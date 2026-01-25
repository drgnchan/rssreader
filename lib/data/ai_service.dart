import 'package:dio/dio.dart';

/// AI 摘要服务，支持 OpenAI 兼容的 API
/// 支持阿里云百炼平台的联网搜索功能
class AiService {
  AiService(this._dio);

  final Dio _dio;

  /// 生成文章摘要
  /// [apiKey] - API 密钥
  /// [baseUrl] - API 基础 URL
  /// [model] - 模型名称
  /// [title] - 文章标题
  /// [content] - 文章内容 (HTML 会被清理)
  /// [articleUrl] - 文章原始链接（可选，用于联网搜索时提供上下文）
  /// [enableSearch] - 是否启用联网搜索（仅阿里云百炼支持）
  Future<String> generateSummary({
    required String apiKey,
    required String title,
    required String content,
    required String baseUrl,
    required String model,
    String? articleUrl,
    bool enableSearch = false,
  }) async {
    final cleanContent = _stripHtml(content);
    // 限制内容长度，避免 token 超限
    final truncated = cleanContent.length > 6000
        ? '${cleanContent.substring(0, 6000)}...'
        : cleanContent;

    // 构建用户消息
    final userContent = StringBuffer('请总结以下文章：\n\n标题：$title\n\n');
    if (articleUrl != null && articleUrl.isNotEmpty) {
      userContent.write('原文链接：$articleUrl\n\n');
    }
    userContent.write('内容：$truncated');

    // 构建系统提示词
    final systemPrompt = enableSearch
        ? '''你是一个专业的文章摘要助手。请用简洁的中文总结文章的核心内容。
要求：
1. 摘要控制在 100-200 字
2. 提取文章的主要观点和关键信息
3. 使用清晰、易懂的语言
4. 如果文章是英文，请用中文总结
5. 如果文章内容不完整或需要更多背景信息，可以通过联网搜索获取相关资料来补充'''
        : '''你是一个专业的文章摘要助手。请用简洁的中文总结文章的核心内容。
要求：
1. 摘要控制在 100-200 字
2. 提取文章的主要观点和关键信息
3. 使用清晰、易懂的语言
4. 如果文章是英文，请用中文总结''';

    try {
      // 构建请求数据
      final requestData = <String, dynamic>{
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent.toString()},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      };

      // 阿里云百炼平台支持联网搜索
      if (enableSearch) {
        requestData['enable_search'] = true;
        requestData['search_options'] = {
          'forced_search': true, // 强制联网搜索
        };
      }

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw Exception('AI 返回结果为空');
      }
      final message = choices[0]['message'] as Map<String, dynamic>;
      return message['content'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 处理 Dio 错误，返回友好的错误信息
  Exception _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String message;
    switch (statusCode) {
      case 401:
        message = 'API Key 无效，请检查设置';
        break;
      case 403:
        message = 'API 访问被拒绝，请检查 API Key 权限或账户余额';
        break;
      case 404:
        message = 'API 地址错误，请检查 Base URL 设置';
        break;
      case 429:
        message = '请求过于频繁，请稍后再试';
        break;
      case 500:
      case 502:
      case 503:
        message = 'AI 服务暂时不可用，请稍后再试';
        break;
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = '网络连接超时，请检查网络';
        } else if (e.type == DioExceptionType.connectionError) {
          message = '无法连接到 AI 服务，请检查网络或 Base URL';
        } else if (responseData is Map && responseData['error'] != null) {
          final error = responseData['error'];
          message = error['message'] ?? '请求失败: $statusCode';
        } else {
          message = '请求失败: ${statusCode ?? e.message}';
        }
    }
    return Exception(message);
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

