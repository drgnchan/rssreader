import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/article_list_controller.dart';
import '../state/filters.dart';
import 'article_detail_screen.dart';

class ArticleListScreen extends ConsumerWidget {
  const ArticleListScreen({super.key, required this.streamId, this.title});

  final String streamId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articleListProvider(streamId));
    final controller = ref.read(articleListProvider(streamId).notifier);
    final unreadAsync = ref.watch(unreadOnlyProvider(streamId));
    final unreadOnly = unreadAsync.valueOrNull ?? false;

    Future<void> onRefresh() async {
      await controller.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? '文章'),
        actions: [
          IconButton(
            tooltip: unreadOnly ? '显示全部' : '仅看未读',
            icon: Icon(unreadOnly ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () {
              ref.read(unreadOnlyProvider(streamId).notifier).toggle();
              controller.refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: articles.when(
          data: (items) {
            final visible = [...items]
              ..sort((a, b) => b.published.compareTo(a.published));
            // Keep already loaded items visible even when marked read locally; the
            // server-side unread filter is applied on refresh/re-enter.
            if (visible.isEmpty) return const Center(child: Text('暂无内容'));
            return ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = visible[index];
                final text = _stripHtml(
                  item.summary?.content ?? item.content?.content ?? '',
                );
                final published = DateTime.fromMillisecondsSinceEpoch(
                  item.published * 1000,
                  isUtc: true,
                ).toLocal().toIso8601String();
                return ListTile(
                  leading: Icon(
                    item.isRead
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.isRead
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        published.substring(0, 16),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: item.isStarred ? '取消星标' : '星标',
                    onPressed: () =>
                        controller.setStarred(item.id, !item.isStarred),
                    icon: Icon(
                      item.isStarred ? Icons.star : Icons.star_border,
                      color: item.isStarred ? Colors.amber : null,
                    ),
                  ),
                  onTap: () {
                    controller.setRead(item.id, true);
                    context.push(
                      '/article',
                      extra: ArticleNav(streamId: streamId, item: item),
                    );
                  },
                  onLongPress: () => controller.setRead(item.id, !item.isRead),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('加载失败: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
