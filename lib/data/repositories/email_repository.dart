import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/services/local_database.dart';
import '../../core/services/sync_service.dart';
import '../../models/email_model.dart';
import '../datasources/remote_datasource.dart';

class FolderPage {
  final List<EmailModel> emails;
  final bool hasMore;
  final bool fromCache;
  const FolderPage(this.emails, {this.hasMore = false, this.fromCache = false});
}

class EmailRepository {
  EmailRepository._();
  static final EmailRepository instance = EmailRepository._();
  final _remote = RemoteDataSource.instance;
  final _local = LocalDatabase.instance;

  /// Network first; on transport failure fall back to what is cached locally.
  Future<ApiResponse<FolderPage>> loadFolder(String folder, {int page = 1, String? labelId}) async {
    final r = await _remote.listFolder(folder, page: page, labelId: labelId);
    if (r.ok) {
      final list = r.data ?? const <EmailModel>[];
      if (labelId == null) await _local.cacheEmails(folder, list, replace: page == 1);
      return ApiResponse.success(FolderPage(list, hasMore: r.meta.hasMore));
    }
    if (page == 1 && labelId == null && (r.error!.isOffline || r.error!.code == 'timeout')) {
      final cached = await _local.cachedEmails(folder);
      if (cached.isNotEmpty) return ApiResponse.success(FolderPage(cached, fromCache: true));
    }
    return ApiResponse.failure(r.error!);
  }

  Future<ApiResponse<EmailModel>> open(String id) => _remote.view(id);
  Future<ApiResponse<List<EmailModel>>> thread(String threadId) => _remote.thread(threadId);
  Future<ApiResponse<List<EmailModel>>> search(Map<String, dynamic> q, {int page = 1}) => _remote.search(q, page: page);

  Future<ApiResponse<void>> _act(String kind, String endpoint, List<String> ids, {Map<String, dynamic>? extra}) async {
    final r = await _remote.action(endpoint, ids, extra: extra);
    if (!r.ok && r.error!.isOffline) {
      await SyncService.instance.queue(kind, {'ids': ids, ...?extra});
      return ApiResponse.success(null);
    }
    return r;
  }

  Future<ApiResponse<void>> archive(List<String> ids) => _act('archive', ApiEndpoints.archive, ids);
  Future<ApiResponse<void>> trash(List<String> ids) => _act('delete', ApiEndpoints.delete, ids);
  Future<ApiResponse<void>> deleteForever(List<String> ids) => _act('delete', ApiEndpoints.delete, ids, extra: {'permanent': true});
  Future<ApiResponse<void>> restore(List<String> ids) => _remote.action(ApiEndpoints.restore, ids);
  Future<ApiResponse<void>> spam(List<String> ids) => _remote.action(ApiEndpoints.delete, ids, extra: {'to': 'spam'});
  Future<ApiResponse<void>> notSpam(List<String> ids) => _remote.action(ApiEndpoints.restore, ids, extra: {'from': 'spam'});
  Future<ApiResponse<void>> star(List<String> ids, bool value) => _act('star', ApiEndpoints.star, ids, extra: {'value': value});
  Future<ApiResponse<void>> markRead(List<String> ids, bool value) => _act('mark_read', ApiEndpoints.markRead, ids, extra: {'value': value});
  Future<ApiResponse<void>> important(List<String> ids, bool value) =>
      _remote.action(ApiEndpoints.star, ids, extra: {'value': value, 'flag': 'important'});
  Future<ApiResponse<void>> snooze(List<String> ids, DateTime until) =>
      _remote.action(ApiEndpoints.snooze, ids, extra: {'until': until.toUtc().toIso8601String()});
  Future<ApiResponse<void>> unsnooze(List<String> ids) =>
      _remote.action(ApiEndpoints.snooze, ids, extra: {'until': null});

  Future<ApiResponse<void>> send(Map<String, dynamic> payload) async {
    final r = await _remote.send(payload);
    if (!r.ok && r.error!.isOffline) {
      await SyncService.instance.queue('send', payload);
      return ApiResponse.success(null); // queued; UI reports "will send when online"
    }
    return r;
  }

  Future<ApiResponse<void>> schedule(Map<String, dynamic> payload) => _remote.schedule(payload);
  Future<ApiResponse<String>> saveDraft(Map<String, dynamic> payload) => _remote.saveDraft(payload);
}
