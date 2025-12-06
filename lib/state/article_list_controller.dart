import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/freshrss_repository.dart';
import '../data/models.dart';
import 'core_providers.dart';
import 'filters.dart';
import 'session_controller.dart';

final articleListProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      ArticleListController,
      List<ItemDto>,
      String
    >(ArticleListController.new);

class ArticleListController
    extends AutoDisposeFamilyAsyncNotifier<List<ItemDto>, String> {
  late String _streamId;

  FreshRssRepository get _repo => ref.read(freshRssRepositoryProvider);

  @override
  Future<List<ItemDto>> build(String streamId) async {
    _streamId = streamId;
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setRead(String itemId, bool read) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(
        previous
            .map((i) => i.id == itemId ? i.copyWith(read: read) : i)
            .toList(),
      );
    }
    try {
      final token = await _requireToken();
      await _repo.markRead(token, itemId, read);
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
    }
  }

  Future<void> setStarred(String itemId, bool starred) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(
        previous
            .map((i) => i.id == itemId ? i.copyWith(starred: starred) : i)
            .toList(),
      );
    }
    try {
      final token = await _requireToken();
      await _repo.markStar(token, itemId, starred);
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
    }
  }

  Future<List<ItemDto>> _fetch() async {
    final unreadOnly = await ref.read(unreadOnlyProvider(_streamId).future);
    final token = await _requireToken();
    return _repo.articles(token, _streamId, unreadOnly: unreadOnly);
  }

  Future<SessionToken> _requireToken() async {
    final session = await ref.read(sessionProvider.future);
    final token = session.token;
    if (token == null) throw StateError('Not authenticated');
    return token;
  }
}
