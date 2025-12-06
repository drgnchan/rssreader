import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../state/session_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedListScreen extends ConsumerWidget {
  const FeedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = ref.watch(subscriptionsProvider);

    Future<void> onRefresh() async {
      await ref.refresh(subscriptionsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅'),
        actions: [
          IconButton(
            tooltip: '退出登录',
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: feeds.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('暂无订阅'));
            }
            final sorted = [...items]
              ..sort((a, b) {
                final ua = a.unreadCount ?? 0;
                final ub = b.unreadCount ?? 0;
                return ub.compareTo(ua);
              });
            return ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final feed = sorted[index];
                final unread = feed.unreadCount;
                return ListTile(
                  leading: _FeedIcon(title: feed.title, htmlUrl: feed.htmlUrl),
                  title: Text(feed.title),
                  subtitle: Text(feed.id),
                  trailing: unread != null
                      ? Chip(label: Text('$unread'))
                      : null,
                  onTap: () => context.push(
                    '/feed/${Uri.encodeComponent(feed.id)}?title=${Uri.encodeComponent(feed.title)}',
                  ),
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
}

class _FeedIcon extends StatelessWidget {
  const _FeedIcon({required this.title, required this.htmlUrl});

  final String title;
  final String? htmlUrl;

  @override
  Widget build(BuildContext context) {
    final url = _faviconUrl(htmlUrl);
    final fallback = CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        title.isNotEmpty ? title.characters.first.toUpperCase() : '?',
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
    if (url == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      ),
    );
  }

  String? _faviconUrl(String? pageUrl) {
    if (pageUrl == null) return null;
    final uri = Uri.tryParse(pageUrl.trim());
    if (uri == null || uri.host.isEmpty) return null;
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    return '$scheme://${uri.host}/favicon.ico';
  }
}
