import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'core_providers.dart';
import 'session_controller.dart';

final subscriptionsProvider = FutureProvider<List<SubscriptionDto>>((
  ref,
) async {
  final session = await ref.watch(sessionProvider.future);
  if (!session.isAuthenticated || session.token == null) {
    throw StateError('Not authenticated');
  }
  final repo = ref.watch(freshRssRepositoryProvider);
  return repo.subscriptions(session.token!);
});
