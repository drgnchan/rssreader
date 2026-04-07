import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state/providers.dart';
import 'state/session_controller.dart';
import 'ui/article_detail_screen.dart';
import 'ui/article_list_screen.dart';
import 'ui/feed_list_screen.dart';
import 'ui/login_screen.dart';
import 'ui/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final refreshListenable = _RouterRefreshNotifier();
  ref.listen<AsyncValue<SessionState>>(sessionProvider, (_, __) {
    refreshListenable.notify();
  });
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/feeds',
        builder: (context, state) => const FeedListScreen(),
      ),
      GoRoute(
        path: '/feed/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final decodedId = Uri.decodeComponent(id);
          final title = state.uri.queryParameters['title'];
          return ArticleListScreen(streamId: decodedId, title: title);
        },
      ),
      GoRoute(
        path: '/article',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! ArticleNav) {
            return const Scaffold(body: Center(child: Text('未找到文章')));
          }
          return ArticleDetailScreen(nav: extra);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';
      if (session.isLoading) return null;
      final authed = session.valueOrNull?.isAuthenticated ?? false;

      if (!authed && !isLoggingIn) return '/login';
      if (authed && (isLoggingIn || isSplash)) return '/feeds';
      return null;
    },
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();

  @override
  void dispose() {
    super.dispose();
  }
}

class ReadyYouApp extends ConsumerWidget {
  const ReadyYouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MyRSSReader',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'OPPOSans',
      ),
      routerConfig: router,
    );
  }
}
