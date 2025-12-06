import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'filter_store.dart';

final filterStoreProvider = Provider<FilterStore>((ref) => FilterStore());

final unreadOnlyProvider =
    AutoDisposeAsyncNotifierProviderFamily<UnreadOnlyController, bool, String>(
      UnreadOnlyController.new,
    );

class UnreadOnlyController
    extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  late String _streamId;

  FilterStore get _store => ref.read(filterStoreProvider);

  @override
  Future<bool> build(String streamId) async {
    _streamId = streamId;
    final stored = await _store.getUnreadOnly(streamId);
    return stored ?? false;
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    final next = !current;
    state = AsyncData(next);
    await _store.setUnreadOnly(_streamId, next);
  }
}
