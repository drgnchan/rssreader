import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/freshrss_repository.dart';
import '../data/models.dart';
import 'core_providers.dart';

class SessionState {
  SessionState({required this.token});

  final SessionToken? token;

  bool get isAuthenticated => token != null;
}

final sessionProvider = AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends AsyncNotifier<SessionState> {
  FreshRssRepository get _repo => ref.read(freshRssRepositoryProvider);

  @override
  Future<SessionState> build() async {
    final token = await _repo.loadSession();
    return SessionState(token: token);
  }

  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _repo.login(
        baseUrl: baseUrl,
        email: email,
        password: password,
      );
      return SessionState(token: token);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.logout();
      return SessionState(token: null);
    });
  }
}
