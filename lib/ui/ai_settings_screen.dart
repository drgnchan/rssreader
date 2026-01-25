import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_settings_store.dart';
import '../state/ai_providers.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

/// 预设配置
enum AiPreset {
  aliyunBailian('阿里云百炼 (推荐)', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'deepseek-v3', true),
  deepseek('DeepSeek 官方', 'https://api.deepseek.com', 'deepseek-chat', false),
  openai('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini', false);

  const AiPreset(this.label, this.baseUrl, this.model, this.supportsSearch);
  final String label;
  final String baseUrl;
  final String model;
  final bool supportsSearch;
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isLoading = false;
  bool _enableSearch = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(aiSettingsProvider.future);
    _apiKeyController.text = settings.apiKey ?? '';
    _baseUrlController.text = settings.baseUrl;
    _modelController.text = settings.model;
    setState(() => _enableSearch = settings.enableSearch);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyPreset(AiPreset preset) {
    setState(() {
      _baseUrlController.text = preset.baseUrl;
      _modelController.text = preset.model;
      _enableSearch = preset.supportsSearch;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final settings = AiSettings(
        apiKey: _apiKeyController.text.trim().isEmpty
            ? null
            : _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        enableSearch: _enableSearch,
      );
      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 设置')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 配置说明卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置说明',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '默认使用阿里云百炼 + DeepSeek，支持联网搜索。\n'
                      '也可切换到 DeepSeek 官方或 OpenAI。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 预设配置选择
            Text('快速配置', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AiPreset.values.map((preset) {
                return ActionChip(
                  label: Text(preset.label),
                  onPressed: () => _applyPreset(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              obscureText: _obscureApiKey,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入 API URL';
                if (!v.startsWith('http')) return '请输入有效的 URL';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'deepseek-v3',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入模型名称' : null,
            ),
            const SizedBox(height: 16),
            // 联网搜索开关
            SwitchListTile(
              title: const Text('启用联网搜索'),
              subtitle: const Text('仅阿里云百炼支持，可获取实时网络信息'),
              value: _enableSearch,
              onChanged: (v) => setState(() => _enableSearch = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

