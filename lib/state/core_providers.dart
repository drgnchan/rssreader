import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/freshrss_api.dart';
import '../data/freshrss_repository.dart';
import '../data/token_store.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  return dio;
});

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(const FlutterSecureStorage()),
);

final freshRssApiProvider = Provider<FreshRssApi>(
  (ref) => FreshRssApi(ref.watch(dioProvider)),
);

final freshRssRepositoryProvider = Provider<FreshRssRepository>((ref) {
  final api = ref.watch(freshRssApiProvider);
  final store = ref.watch(tokenStoreProvider);
  return FreshRssRepository(api: api, tokenStore: store);
});
