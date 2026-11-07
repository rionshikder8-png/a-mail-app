/// Standard response envelope shared with the planned PHP backend:
/// { "success": bool, "data": any, "error": {"code","message","fields"}, "meta": {"page","per_page","total","has_more"} }
class ApiError {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String> fields;

  const ApiError({required this.code, required this.message, this.statusCode, this.fields = const {}});

  bool get isOffline => code == 'offline';
  bool get isNotConfigured => code == 'backend_unavailable';
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class PageMeta {
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;
  const PageMeta({this.page = 1, this.perPage = 25, this.total = 0, this.hasMore = false});

  factory PageMeta.fromJson(Map<String, dynamic>? j) => j == null
      ? const PageMeta()
      : PageMeta(
          page: (j['page'] ?? 1) as int,
          perPage: (j['per_page'] ?? 25) as int,
          total: (j['total'] ?? 0) as int,
          hasMore: j['has_more'] == true,
        );
}

class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final PageMeta meta;

  const ApiResponse._({this.data, this.error, this.meta = const PageMeta()});

  bool get ok => error == null;

  factory ApiResponse.success(T? data, {PageMeta meta = const PageMeta()}) =>
      ApiResponse._(data: data, meta: meta);

  factory ApiResponse.failure(ApiError error) => ApiResponse._(error: error);

  ApiResponse<R> map<R>(R Function(T data) f) => ok
      ? ApiResponse<R>.success(data == null ? null : f(data as T), meta: meta)
      : ApiResponse<R>.failure(error!);
}
