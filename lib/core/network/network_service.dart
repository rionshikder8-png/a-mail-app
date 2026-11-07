import 'package:dio/dio.dart';
import 'api_response.dart';

/// Maps transport exceptions to the app's ApiError model.
class NetworkService {
  NetworkService._();

  static ApiError mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(code: 'timeout', message: 'The server took too long to respond. Please try again.');
      case DioExceptionType.connectionError:
        return const ApiError(
          code: 'offline',
          message: 'Can\'t reach A-Mail servers. Check your connection or the server address in Settings.',
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final body = e.response?.data;
        if (body is Map && body['error'] is Map) {
          final err = Map<String, dynamic>.from(body['error'] as Map);
          final fields = <String, String>{};
          if (err['fields'] is Map) {
            (err['fields'] as Map).forEach((k, v) => fields['$k'] = '$v');
          }
          return ApiError(
            code: '${err['code'] ?? 'error'}',
            message: '${err['message'] ?? 'Something went wrong.'}',
            statusCode: status,
            fields: fields,
          );
        }
        if (status == 404 || status == 502 || status == 503) {
          return ApiError(
            code: 'backend_unavailable',
            message: 'The A-Mail service is not available yet.',
            statusCode: status,
          );
        }
        return ApiError(code: 'http_$status', message: 'Request failed (${status ?? '?'}).', statusCode: status);
      case DioExceptionType.cancel:
        return const ApiError(code: 'cancelled', message: 'Request cancelled.');
      default:
        return const ApiError(code: 'unknown', message: 'Something went wrong. Please try again.');
    }
  }
}
