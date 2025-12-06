import 'package:dio/dio.dart';

import 'models.dart';

class FreshRssApi {
  FreshRssApi(this._dio);

  final Dio _dio;

  Future<String> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final uri = _resolve(baseUrl, 'api/greader.php/accounts/ClientLogin');
    final res = await _dio.postUri(
      uri,
      data: {
        'Email': email,
        'Passwd': password,
        'service': 'reader',
        'accountType': 'HOSTED_OR_GOOGLE',
        'output': 'token',
        'source': 'ReadYouFlutter',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final sid = _parseSid(res.data.toString());
    if (sid == null) {
      throw const FormatException('FreshRSS login did not return SID');
    }
    return sid;
  }

  Future<SubscriptionListDto> subscriptions({
    required String baseUrl,
    required String authHeader,
  }) async {
    final uri = _resolve(
      baseUrl,
      'api/greader.php/reader/api/0/subscription/list',
    );
    final res = await _dio.getUri(
      uri.replace(queryParameters: {'output': 'json'}),
      options: Options(headers: {'Authorization': authHeader}),
    );
    return SubscriptionListDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UnreadCountDto> unreadCounts({
    required String baseUrl,
    required String authHeader,
  }) async {
    final uri = _resolve(baseUrl, 'api/greader.php/reader/api/0/unread-count');
    final res = await _dio.getUri(
      uri.replace(queryParameters: {'output': 'json'}),
      options: Options(headers: {'Authorization': authHeader}),
    );
    return UnreadCountDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StreamContentDto> streamContents({
    required String baseUrl,
    required String authHeader,
    required String streamId,
    int limit = 40,
    bool excludeRead = false,
  }) async {
    final encoded = Uri.encodeComponent(streamId);
    final uri = _resolve(
      baseUrl,
      'api/greader.php/reader/api/0/stream/contents/$encoded',
    );
    final res = await _dio.getUri(
      uri.replace(queryParameters: {
        'output': 'json',
        'n': '$limit',
        'r': 'o',
        if (excludeRead) 'xt': 'user/-/state/com.google/read',
      }),
      options: Options(headers: {'Authorization': authHeader}),
    );
    return StreamContentDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> editTag({
    required String baseUrl,
    required String authHeader,
    required String itemId,
    String? addTag,
    String? removeTag,
  }) async {
    final uri = _resolve(baseUrl, 'api/greader.php/reader/api/0/edit-tag');
    await _dio.postUri(
      uri,
      data: {
        'i': itemId,
        if (addTag != null) 'a': addTag,
        if (removeTag != null) 'r': removeTag,
        'ac': 'edit-tags',
      },
      options: Options(
        headers: {'Authorization': authHeader},
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Uri _resolve(String baseUrl, String path) => Uri.parse(baseUrl).resolve(path);

  String? _parseSid(String body) => body
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.startsWith('SID='), orElse: () => '')
      .replaceFirst('SID=', '')
      .nullIfEmpty;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
