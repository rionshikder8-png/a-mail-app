import '../../core/network/api_response.dart';
import '../../models/attachment_model.dart';
import '../../models/contact_model.dart';
import '../../models/label_model.dart';
import '../../models/notification_model.dart';
import '../../models/storage_model.dart';
import '../../models/user_model.dart';
import '../datasources/remote_datasource.dart';

/// Labels, contacts, notifications, devices, storage and profile calls.
class MiscRepository {
  MiscRepository._();
  static final MiscRepository instance = MiscRepository._();
  final _r = RemoteDataSource.instance;

  Future<ApiResponse<List<LabelModel>>> labels() => _r.labels();
  Future<ApiResponse<LabelModel>> createLabel(String n, int c) => _r.createLabel(n, c);
  Future<ApiResponse<LabelModel>> updateLabel(String id, String n, int c) => _r.updateLabel(id, n, c);
  Future<ApiResponse<void>> deleteLabel(String id) => _r.deleteLabel(id);
  Future<ApiResponse<void>> assignLabel(List<String> ids, String labelId, bool add) => _r.assignLabel(ids, labelId, add);

  Future<ApiResponse<List<ContactModel>>> contacts() => _r.contacts();
  Future<ApiResponse<ContactModel>> createContact(ContactModel c) => _r.createContact(c);
  Future<ApiResponse<ContactModel>> updateContact(ContactModel c) => _r.updateContact(c);
  Future<ApiResponse<void>> deleteContact(String id) => _r.deleteContact(id);

  Future<ApiResponse<List<NotificationModel>>> notifications() => _r.notifications();
  Future<ApiResponse<void>> markNotificationsRead(List<String> ids) => _r.markNotificationsRead(ids);
  Future<ApiResponse<void>> registerDevice(String token, String platform, String name) =>
      _r.registerDevice(token, platform, name);
  Future<ApiResponse<void>> savePrefs(Map<String, dynamic> p) => _r.savePrefs(p);

  Future<ApiResponse<List<Map<String, dynamic>>>> devices() => _r.devices();
  Future<ApiResponse<void>> revokeDevice(String id) => _r.revokeDevice(id);
  Future<ApiResponse<List<Map<String, dynamic>>>> loginHistory() => _r.loginHistory();

  Future<ApiResponse<StorageModel>> storage() => _r.storage();
  Future<ApiResponse<List<AttachmentModel>>> storageAttachments() => _r.storageAttachments();

  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> f) => _r.updateProfile(f);
  Future<ApiResponse<void>> changePassword(String c, String n) => _r.changePassword(c, n);
  Future<ApiResponse<void>> setTwoFactor(bool v) => _r.setTwoFactor(v);
  Future<ApiResponse<void>> deleteAccount(String pw) => _r.deleteAccount(pw);
}
