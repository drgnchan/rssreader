import 'freshrss_api.dart';
import 'models.dart';
import 'token_store.dart';

class FreshRssRepository {
  FreshRssRepository({required FreshRssApi api, required TokenStore tokenStore})
    : _api = api,
      _tokenStore = tokenStore;

  final FreshRssApi _api;
  final TokenStore _tokenStore;

  Future<SessionToken?> loadSession() => _tokenStore.read();

  Future<SessionToken> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final sid = await _api.login(
      baseUrl: baseUrl,
      email: email,
      password: password,
    );
    final token = SessionToken(
      baseUrl: _normalizeBaseUrl(baseUrl),
      sid: sid,
      email: email,
    );
    await _tokenStore.save(
      baseUrl: token.baseUrl,
      sid: token.sid,
      email: token.email,
    );
    return token;
  }

  Future<void> logout() => _tokenStore.clear();

  Future<List<SubscriptionDto>> subscriptions(SessionToken token) async {
    final auth = token.authHeader();
    final subs = await _api.subscriptions(
      baseUrl: token.baseUrl,
      authHeader: auth,
    );
    final unread = await _api.unreadCounts(
      baseUrl: token.baseUrl,
      authHeader: auth,
    );
    final unreadMap = {
      for (final item in unread.unreadcounts) item.id: item.count,
    };
    return subs.subscriptions
        .map((s) => s.withUnread(unreadMap[s.id]))
        .toList();
  }

  Future<List<ItemDto>> articles(
    SessionToken token,
    String streamId, {
    bool unreadOnly = false,
  }) async {
    final auth = token.authHeader();
    final stream = await _api.streamContents(
      baseUrl: token.baseUrl,
      authHeader: auth,
      streamId: streamId,
      excludeRead: unreadOnly,
    );
    return stream.items;
  }

  Future<void> markRead(SessionToken token, String itemId, bool read) async {
    final tag = 'user/-/state/com.google/read';
    await _api.editTag(
      baseUrl: token.baseUrl,
      authHeader: token.authHeader(),
      itemId: itemId,
      addTag: read ? tag : null,
      removeTag: read ? null : tag,
    );
  }

  Future<void> markStar(SessionToken token, String itemId, bool starred) async {
    final tag = 'user/-/state/com.google/starred';
    await _api.editTag(
      baseUrl: token.baseUrl,
      authHeader: token.authHeader(),
      itemId: itemId,
      addTag: starred ? tag : null,
      removeTag: starred ? null : tag,
    );
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) return trimmed;
    return '$trimmed/';
  }
}
