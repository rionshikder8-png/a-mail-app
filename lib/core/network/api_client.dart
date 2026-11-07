import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../constants/api_endpoints.dart';
import '../security/token_manager.dart';
import 'api_response.dart';
import 'network_service.dart';

typedef SessionExpiredCallback = void Function();

/// Single HTTP entry point. Adds bearer auth, rotates refresh tokens on 401
/// (once, de-duplicated) and normalises every outcome into [ApiResponse].
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Accept': 'application/json', 'X-Client': 'a-mail-app/1.0'},
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      o.baseUrl = ApiConfig.apiRoot;
      final t = TokenManager.instance.accessToken;
      if (t != null && o.extra['auth'] != false) o.headers['Authorization'] = 'Bearer $t';
      if (ApiConfig.logRequests && kDebugMode) debugPrint('[api] ${o.method} ${o.uri}');
      h.next(o);
    }));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  Completer<bool>? _refreshing;
  SessionExpiredCallback? onSessionExpired;

  Future<ApiResponse<T>> get<T>(String path,
          {Map<String, dynamic>? query, T Function(dynamic data)? parse, bool auth = true}) =>
      _send('GET', path, query: query, parse: parse, auth: auth);

  Future<ApiResponse<T>> post<T>(String path,
          {Object? body, Map<String, dynamic>? query, T Function(dynamic data)? parse, bool auth = true}) =>
      _send('POST', path, body: body, query: query, parse: parse, auth: auth);

  Future<ApiResponse<T>> put<T>(String path,
          {Object? body, T Function(dynamic data)? parse}) =>
      _send('PUT', path, body: body, parse: parse);

  Future<ApiResponse<T>> delete<T>(String path,
          {Object? body, Map<String, dynamic>? query, T Function(dynamic data)? parse}) =>
      _send('DELETE', path, body: body, query: query, parse: parse);

  Future<ApiResponse<T>> upload<T>(String path, FormData form,
      {void Function(int, int)? onProgress, T Function(dynamic data)? parse}) async {
    try {
      final r = await _dio.post(path, data: form, onSendProgress: onProgress);
      return _wrap(r, parse);
    } on DioException catch (e) {
      return ApiResponse.failure(NetworkService.mapDioError(e));
    }
  }

  Future<ApiResponse<String>> download(String url, String savePath, {void Function(int, int)? onProgress}) async {
    try {
      await _dio.download(url, savePath, onReceiveProgress: onProgress);
      return ApiResponse.success(savePath);
    } on DioException catch (e) {
      return ApiResponse.failure(NetworkService.mapDioError(e));
    }
  }

  Future<ApiResponse<T>> _send<T>(String method, String path,
      {Object? body, Map<String, dynamic>? query, T Function(dynamic data)? parse, bool auth = true, bool retried = false}) async {
    try {
      final r = await _dio.request(path,
          data: body, queryParameters: query, options: Options(method: method, extra: {'auth': auth}));
      return _wrap(r, parse);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && auth && !retried && TokenManager.instance.hasSession) {
        if (await _refresh()) {
          return _send(method, path, body: body, query: query, parse: parse, auth: auth, retried: true);
        }
        onSessionExpired?.call();
      }
      return ApiResponse.failure(NetworkService.mapDioError(e));
    } catch (_) {
      return ApiResponse.failure(const ApiError(code: 'unknown', message: 'Unexpected response from server.'));
    }
  }

  ApiResponse<T> _wrap<T>(Response r, T Function(dynamic)? parse) {
    final b = r.data;
    if (b is Map && b['success'] == false) {
      final err = b['error'] is Map ? Map<String, dynamic>.from(b['error'] as Map) : <String, dynamic>{};
      return ApiResponse.failure(ApiError(
          code: '${err['code'] ?? 'error'}', message: '${err['message'] ?? 'Request failed.'}', statusCode: r.statusCode));
    }
    final payload = (b is Map && b.containsKey('data')) ? b['data'] : b;
    final meta = (b is Map && b['meta'] is Map) ? PageMeta.fromJson(Map<String, dynamic>.from(b['meta'] as Map)) : const PageMeta();
    try {
      return ApiResponse.success(parse != null ? parse(payload) : payload as T?, meta: meta);
    } catch (_) {
      return ApiResponse.failure(const ApiError(code: 'parse', message: 'Received an unexpected response format.'));
    }
  }

  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    try {
      final r = await _dio.post(ApiEndpoints.refreshToken,
          data: {'refresh_token': TokenManager.instance.refreshToken}, options: Options(extra: {'auth': false}));
      final d = (r.data is Map && r.data['data'] is Map) ? r.data['data'] as Map : (r.data as Map);
      await TokenManager.instance.save(access: '${d['access_token']}', refresh: '${d['refresh_token']}');
      c.complete(true);
    } catch (_) {
      await TokenManager.instance.clear();
      c.complete(false);
    } finally {
      _refreshing = null;
    }
    return c.future;
  }
}
