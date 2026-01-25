import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/ai_service.dart';
import '../data/ai_settings_store.dart';
import 'core_providers.dart';

/// AI 设置存储 Provider
final aiSettingsStoreProvider = Provider<AiSettingsStore>(
  (ref) => AiSettingsStore(const FlutterSecureStorage()),
);

/// AI 服务 Provider
final aiServiceProvider = Provider<AiService>(
  (ref) => AiService(ref.watch(dioProvider)),
);

/// AI 设置 Provider
final aiSettingsProvider =
    AsyncNotifierProvider<AiSettingsNotifier, AiSettings>(
  AiSettingsNotifier.new,
);

class AiSettingsNotifier extends AsyncNotifier<AiSettings> {
  @override
  Future<AiSettings> build() async {
    final store = ref.read(aiSettingsStoreProvider);
    return store.read();
  }

  Future<void> updateSettings(AiSettings settings) async {
    final store = ref.read(aiSettingsStoreProvider);
    await store.save(settings);
    state = AsyncData(settings);
  }
}

/// 文章摘要缓存 Provider (articleId -> summary)
final summaryCache = StateProvider<Map<String, String>>((ref) => {});

/// 单篇文章摘要 Provider
final articleSummaryProvider = AsyncNotifierProviderFamily<
    ArticleSummaryNotifier, String?, ArticleSummaryParams>(
  ArticleSummaryNotifier.new,
);

class ArticleSummaryParams {
  ArticleSummaryParams({
    required this.articleId,
    required this.title,
    required this.content,
    this.url,
  });

  final String articleId;
  final String title;
  final String content;
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleSummaryParams &&
          runtimeType == other.runtimeType &&
          articleId == other.articleId;

  @override
  int get hashCode => articleId.hashCode;
}

class ArticleSummaryNotifier
    extends FamilyAsyncNotifier<String?, ArticleSummaryParams> {
  @override
  Future<String?> build(ArticleSummaryParams arg) async {
    // 检查缓存
    final cache = ref.read(summaryCache);
    if (cache.containsKey(arg.articleId)) {
      return cache[arg.articleId];
    }
    return null;
  }

  Future<void> generate() async {
    final settings = await ref.read(aiSettingsProvider.future);
    if (!settings.isConfigured) {
      throw Exception('请先配置 AI API Key');
    }

    state = const AsyncLoading();

    try {
      final service = ref.read(aiServiceProvider);
      final summary = await service.generateSummary(
        apiKey: settings.apiKey!,
        baseUrl: settings.baseUrl,
        model: settings.model,
        title: arg.title,
        content: arg.content,
        articleUrl: arg.url,
        enableSearch: settings.enableSearch,
      );
      // 更新缓存
      ref.read(summaryCache.notifier).update((cache) {
        return {...cache, arg.articleId: summary};
      });

      state = AsyncData(summary);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

