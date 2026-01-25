import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AI 设置存储
class AiSettingsStore {
  AiSettingsStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyApiKey = 'ai_api_key';
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyModel = 'ai_model';
  static const _keyEnableSearch = 'ai_enable_search';

  // 默认使用阿里云百炼，支持联网搜索
  static const defaultBaseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const defaultModel = 'deepseek-v3';
  static const defaultEnableSearch = true;

  Future<AiSettings> read() async {
    final values = await _storage.readAll();
    return AiSettings(
      apiKey: values[_keyApiKey],
      baseUrl: values[_keyBaseUrl] ?? defaultBaseUrl,
      model: values[_keyModel] ?? defaultModel,
      enableSearch: values[_keyEnableSearch] == 'true' ||
          (values[_keyEnableSearch] == null && defaultEnableSearch),
    );
  }

  Future<void> save(AiSettings settings) async {
    if (settings.apiKey != null) {
      await _storage.write(key: _keyApiKey, value: settings.apiKey);
    } else {
      await _storage.delete(key: _keyApiKey);
    }
    await _storage.write(key: _keyBaseUrl, value: settings.baseUrl);
    await _storage.write(key: _keyModel, value: settings.model);
    await _storage.write(key: _keyEnableSearch, value: settings.enableSearch.toString());
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyBaseUrl);
    await _storage.delete(key: _keyModel);
    await _storage.delete(key: _keyEnableSearch);
  }
}

class AiSettings {
  AiSettings({
    this.apiKey,
    this.baseUrl = AiSettingsStore.defaultBaseUrl,
    this.model = AiSettingsStore.defaultModel,
    this.enableSearch = AiSettingsStore.defaultEnableSearch,
  });

  final String? apiKey;
  final String baseUrl;
  final String model;
  final bool enableSearch;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  AiSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? enableSearch,
  }) {
    return AiSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      enableSearch: enableSearch ?? this.enableSearch,
    );
  }
}

