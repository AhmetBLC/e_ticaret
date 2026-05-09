import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/debug/app_debug_log.dart';
import '../../../core/network/api_exception.dart';
import '../local/session_storage.dart';

/// HTTP client for JSON REST API (Express backend).
/// Attaches [Authorization: Bearer …] when a token exists in [SessionStorage].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required SessionStorage sessionStorage,
    this.timeout = const Duration(seconds: 30),
  }) : _session = sessionStorage;

  final String baseUrl;
  final SessionStorage _session;
  final Duration timeout;

  Future<void> Function()? _onSessionExpired;

  /// Called after construction (e.g. from [EticaretApp]) so [AuthProvider] exists.
  void setOnSessionExpired(Future<void> Function()? cb) {
    _onSessionExpired = cb;
  }

  static void _trace(String line) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[API] $line');
  }

  static String _truncateBody(String raw, [int maxChars = 280]) {
    if (raw.length <= maxChars) {
      return raw;
    }
    return '${raw.substring(0, maxChars)}…';
  }

  Future<Map<String, String>> _headers() async {
    final token = await _session.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    final base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base/$p').replace(queryParameters: query);
  }

  Future<void> _notifyUnauthorized() async {
    final cb = _onSessionExpired;
    if (cb != null) {
      await cb();
    }
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(timeout);
    } on TimeoutException {
      _trace('✗ network timeout after ${timeout.inSeconds}s');
      throw ApiException(
        'Bağlantı zaman aşımına uğradı. Sunucu yanıt vermiyor veya ağ yavaş.',
        statusCode: 408,
        code: 'TIMEOUT',
      );
    } catch (e) {
      final errStr = e.toString();
      _trace('✗ network error: $errStr');
      
      if (errStr.contains('SocketException')) {
        throw ApiException(
          'Sunucuya ulaşılamıyor. Ağınızı kontrol edin.',
          code: 'NETWORK',
        );
      }
      
      if (e is http.ClientException) {
         throw ApiException(
          'Ağ hatası: ${e.message}',
          code: 'NETWORK',
        );
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    _trace('→ GET $uri');
    final res = await _send(http.get(uri, headers: await _headers()));
    _trace('← GET ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(path);
    _trace('→ POST $uri');
    final res = await _send(
      http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
    _trace('← POST ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields,
    String fileKey,
    XFile file,
  ) async {
    final uri = _uri(path);
    _trace('→ POST (multipart) $uri');
    final headers = await _headers();
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields);

    final String ext = file.name.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (ext == 'png') mimeType = 'image/png';
    if (ext == 'webp') mimeType = 'image/webp';
    if (ext == 'gif') mimeType = 'image/gif';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        fileKey,
        bytes,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        fileKey,
        file.path,
        contentType: MediaType.parse(mimeType),
      ));
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    _trace(
        '← POST (multipart) ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    _trace('→ PUT $uri');
    final res = await _send(
      http.put(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    _trace('← PUT ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    _trace('→ PATCH $uri');
    final res = await _send(
      http.patch(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    _trace('← PATCH ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = _uri(path);
    _trace('→ DELETE $uri');
    final res = await _send(http.delete(uri, headers: await _headers()));
    _trace('← DELETE ${res.statusCode} ${uri.path} (${res.bodyBytes.length} B)');
    return _parseJson(res);
  }

  Future<Map<String, dynamic>> _parseJson(http.Response res) async {
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e, st) {
      appDebugError(
        'API',
        e,
        st,
        'invalid JSON status=${res.statusCode} snippet=${_truncateBody(res.body)}',
      );
      throw ApiException(
        'Sunucudan geçersiz yanıt (${res.statusCode}).',
        statusCode: res.statusCode,
        code: 'INVALID_RESPONSE',
      );
    }

    final success = body['success'] as bool?;

    if (success == false) {
      final err = body['error'];
      var msg = 'İstek başarısız';
      String? code;
      if (err is Map<String, dynamic>) {
        msg = err['message'] as String? ?? msg;
        code = err['code'] as String?;
      }
      _trace('✗ API error HTTP ${res.statusCode} code=${code ?? '?'} msg=$msg');
      if (code == 'UNAUTHORIZED') {
        await _notifyUnauthorized();
      }
      throw ApiException(msg, statusCode: res.statusCode, code: code);
    }

    if (res.statusCode >= 400 && success != false) {
      final fallback = body['message'] as String? ?? 'HTTP ${res.statusCode}';
      _trace('✗ HTTP ${res.statusCode} $fallback');
      throw ApiException(
        fallback,
        statusCode: res.statusCode,
      );
    }

    return body;
  }
}
