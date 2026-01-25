import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../state/ai_providers.dart';
import '../state/article_list_controller.dart';

class ArticleNav {
  ArticleNav({required this.streamId, required this.item});

  final String streamId;
  final ItemDto item;
}

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.nav});

  final ArticleNav nav;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _markReadOnce());
  }

  Future<void> _markReadOnce() async {
    if (_marked) return;
    _marked = true;
    await ref
        .read(articleListProvider(widget.nav.streamId).notifier)
        .setRead(widget.nav.item.id, true);
  }

  @override
  Widget build(BuildContext context) {
    final articles = ref.watch(articleListProvider(widget.nav.streamId));
    final controller = ref.read(
      articleListProvider(widget.nav.streamId).notifier,
    );
    final item = _resolveItem(articles) ?? widget.nav.item;
    final sorted = _sortedItems(articles);
    final currentIndex = sorted.indexWhere((i) => i.id == item.id);
    final previousItem =
        currentIndex > 0 ? sorted[currentIndex - 1] : null;
    final nextItem =
        currentIndex >= 0 && currentIndex < sorted.length - 1
            ? sorted[currentIndex + 1]
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: item.isRead ? '标记为未读' : '标记为已读',
            icon: Icon(
              item.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
            ),
            onPressed: () => controller.setRead(item.id, !item.isRead),
          ),
          IconButton(
            tooltip: item.isStarred ? '取消星标' : '星标',
            icon: Icon(item.isStarred ? Icons.star : Icons.star_border),
            onPressed: () => controller.setStarred(item.id, !item.isStarred),
          ),
        ],
      ),
      body: articles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (_) => Row(
          children: [
            Expanded(
              child: _ArticleBody(
                item: item,
                onOpenInBrowser: () => _openInBrowser(item),
                onLinkTap: (url) => _handleLinkTap(url),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.only(right: 16),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: previousItem == null
                            ? null
                            : () => _navigateTo(previousItem),
                        child: const Icon(Icons.chevron_left),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: nextItem == null
                            ? null
                            : () => _navigateTo(nextItem),
                        child: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    final uri = _normalizeUrl(url);
    if (uri == null) {
      _showError('无法打开链接: $url');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('无法打开链接: $url');
    }
  }

  ItemDto? _resolveItem(AsyncValue<List<ItemDto>> articles) {
    final list = articles.valueOrNull;
    if (list == null) return null;
    return list.where((i) => i.id == widget.nav.item.id).toList().firstOrNull;
  }

  List<ItemDto> _sortedItems(AsyncValue<List<ItemDto>> articles) {
    final list = articles.valueOrNull;
    if (list == null) return const [];
    final sorted = [...list]
      ..sort((a, b) => b.published.compareTo(a.published));
    return sorted;
  }

  void _navigateTo(ItemDto item) {
    if (!mounted) return;
    context.pushReplacement(
      '/article',
      extra: ArticleNav(streamId: widget.nav.streamId, item: item),
    );
  }

  Future<void> _openInBrowser(ItemDto item) async {
    final uri = _normalizeUrl(item.alternate?.href);
    if (uri == null) {
      _showError('无法打开链接');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('无法打开链接: ${uri.toString()}');
    }
  }

  Uri? _normalizeUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return parsed;
    return Uri.tryParse('https://$trimmed');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({
    required this.item,
    required this.onOpenInBrowser,
    required this.onLinkTap,
  });

  final ItemDto item;
  final VoidCallback onOpenInBrowser;
  final Function(String?) onLinkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final html =
        item.content?.content ?? item.summary?.content ?? '<p>暂无内容</p>';
    final published = DateTime.fromMillisecondsSinceEpoch(
      item.published * 1000,
      isUtc: true,
    ).toLocal().toIso8601String();

    final summaryParams = ArticleSummaryParams(
      articleId: item.id,
      title: item.title,
      content: html,
    );
    final summaryAsync = ref.watch(articleSummaryProvider(summaryParams));

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpenInBrowser,
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.author != null) Text(item.author!),
                const SizedBox(width: 12),
                Text(published.substring(0, 16)),
              ],
            ),
            if (item.alternate?.href.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                item.alternate!.href,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
              ),
            ],
            const SizedBox(height: 16),
            // AI 摘要区域
            _SummaryCard(
              summaryAsync: summaryAsync,
              onGenerate: () {
                ref.read(articleSummaryProvider(summaryParams).notifier).generate();
              },
              onSettings: () => context.push('/settings/ai'),
            ),
            const SizedBox(height: 16),
            Html(
              data: html,
              style: {
                "img": Style(
                  width: Width(100, Unit.percent),
                  height: Height.auto(),
                ),
                "a": Style(
                  textDecoration: TextDecoration.none,
                ),
              },
              onLinkTap: (url, context, attributes) => onLinkTap(url),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI 摘要卡片组件
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summaryAsync,
    required this.onGenerate,
    required this.onSettings,
  });

  final AsyncValue<String?> summaryAsync;
  final VoidCallback onGenerate;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'AI 摘要',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings, size: 18),
                  tooltip: 'AI 设置',
                  onPressed: onSettings,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return OutlinedButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('生成摘要'),
                  );
                }
                return Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('正在生成摘要...'),
                ],
              ),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '生成失败: $e',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
