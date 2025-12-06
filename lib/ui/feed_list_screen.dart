import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../state/session_controller.dart';

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
