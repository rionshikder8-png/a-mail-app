import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../models/attachment_model.dart';
import '../../models/contact_model.dart';
import '../../models/email_model.dart';
import '../../models/label_model.dart';
import '../../models/notification_model.dart';
import '../../models/storage_model.dart';
import '../../models/user_model.dart';

/// All calls to the (future) A-Mail REST API live here. Request/response shapes
/// follow docs/API_CONTRACT.md in this repo.
class RemoteDataSource {
  RemoteDataSource._();
  static final RemoteDataSource instance = RemoteDataSource._();
  ApiClient get _c => ApiClient.instance;

  Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);
  List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---------- Auth ----------
  Future<ApiResponse<bool>> usernameAvailable(String username) => _c.get<bool>(
      ApiEndpoints.usernameAvailable,
      query: {'username': username},
      auth: false,
      parse: (d) => _map(d)['available'] == true);

  Future<ApiResponse<Map<String, dynamic>>> register(
          {required String username, required String password, required String displayName, String? recoveryEmail}) =>
      _c.post(ApiEndpoints.register,
          auth: false,
          body: {
            'username': username,
            'password': password,
            'display_name': displayName,
            if (recoveryEmail != null && recoveryEmail.isNotEmpty) 'recovery_email': recoveryEmail,
          },
          parse: _map);

  Future<ApiResponse<Map<String, dynamic>>> login(String username, String password,
          {required String deviceName, required String platform}) =>
      _c.post(ApiEndpoints.login,
          auth: false,
          body: {'username': username, 'password': password, 'device_name': deviceName, 'platform': platform},
          parse: _map);

  Future<ApiResponse<Map<String, dynamic>>> twoFactorLogin(String challengeId, String code) =>
      _c.post(ApiEndpoints.twoFactor, auth: false, body: {'challenge_id': challengeId, 'code': code}, parse: _map);

  Future<ApiResponse<void>> logout() => _c.post<void>(ApiEndpoints.logout);

  Future<ApiResponse<void>> forgotPassword(String identifier) =>
      _c.post<void>(ApiEndpoints.forgotPassword, auth: false, body: {'identifier': identifier});

  Future<ApiResponse<void>> verifyOtp(String identifier, String code, String purpose) =>
      _c.post<void>(ApiEndpoints.verifyOtp, auth: false, body: {'identifier': identifier, 'code': code, 'purpose': purpose});

  Future<ApiResponse<void>> verifyEmail(String code) =>
      _c.post<void>(ApiEndpoints.verifyEmail, body: {'code': code});

  Future<ApiResponse<void>> resendVerification() =>
      _c.post<void>(ApiEndpoints.verifyEmail, body: {'resend': true});

  Future<ApiResponse<void>> resetPassword(String identifier, String code, String newPassword) =>
      _c.post<void>(ApiEndpoints.resetPassword,
          auth: false, body: {'identifier': identifier, 'code': code, 'new_password': newPassword});

  // ---------- Users ----------
  Future<ApiResponse<UserModel>> profile() =>
      _c.get(ApiEndpoints.profile, parse: (d) => UserModel.fromJson(_map(d)));

  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> fields) =>
      _c.post(ApiEndpoints.updateProfile, body: fields, parse: (d) => UserModel.fromJson(_map(d)));

  Future<ApiResponse<void>> changePassword(String current, String next) =>
      _c.post<void>(ApiEndpoints.changePassword, body: {'current_password': current, 'new_password': next});

  Future<ApiResponse<void>> setTwoFactor(bool enable) =>
      _c.post<void>(ApiEndpoints.twoFactor, body: {'enable': enable});

  Future<ApiResponse<void>> deleteAccount(String password) =>
      _c.post<void>(ApiEndpoints.deleteAccount, body: {'password': password});

  // ---------- Emails ----------
  String _folderPath(String folder) {
    switch (folder) {
      case 'starred':
        return ApiEndpoints.starred;
      case 'important':
        return ApiEndpoints.important;
      case 'all':
        return ApiEndpoints.allMail;
      case 'spam':
        return ApiEndpoints.spam;
      case 'trash':
        return ApiEndpoints.trash;
      case 'scheduled':
        return ApiEndpoints.scheduled;
      case 'sent':
        return ApiEndpoints.sent;
      case 'drafts':
        return ApiEndpoints.drafts;
      default:
        return ApiEndpoints.inbox;
    }
  }

  Future<ApiResponse<List<EmailModel>>> listFolder(String folder, {int page = 1, int perPage = 25, String? labelId}) =>
      _c.get(_folderPath(folder),
          query: {
            'page': page,
            'per_page': perPage,
            if (folder == 'snoozed') 'snoozed': 1,
            if (labelId != null) 'label_id': labelId,
          },
          parse: (d) => _list(d).map(EmailModel.fromJson).toList());

  Future<ApiResponse<EmailModel>> view(String id) =>
      _c.get(ApiEndpoints.viewEmail, query: {'id': id}, parse: (d) => EmailModel.fromJson(_map(d)));

  Future<ApiResponse<List<EmailModel>>> thread(String threadId) => _c.get(ApiEndpoints.viewEmail,
      query: {'thread_id': threadId}, parse: (d) => _list(d).map(EmailModel.fromJson).toList());

  Future<ApiResponse<List<EmailModel>>> search(Map<String, dynamic> q, {int page = 1}) =>
      _c.get(ApiEndpoints.search, query: {...q, 'page': page}, parse: (d) => _list(d).map(EmailModel.fromJson).toList());

  Future<ApiResponse<void>> action(String endpoint, List<String> ids, {Map<String, dynamic>? extra}) =>
      _c.post<void>(endpoint, body: {'ids': ids, ...?extra});

  Future<ApiResponse<void>> send(Map<String, dynamic> payload) =>
      _c.post<void>(ApiEndpoints.sendEmail, body: payload);

  Future<ApiResponse<void>> schedule(Map<String, dynamic> payload) =>
      _c.post<void>(ApiEndpoints.schedule, body: payload);

  Future<ApiResponse<String>> saveDraft(Map<String, dynamic> payload) =>
      _c.post(ApiEndpoints.saveDraft, body: payload, parse: (d) => '${_map(d)['id']}');

  // ---------- Attachments ----------
  Future<ApiResponse<AttachmentModel>> uploadAttachment(String path, String name,
      {void Function(int, int)? onProgress}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: name)});
    return _c.upload(ApiEndpoints.attachmentUpload, form,
        onProgress: onProgress, parse: (d) => AttachmentModel.fromJson(_map(d)));
  }

  // ---------- Labels ----------
  Future<ApiResponse<List<LabelModel>>> labels() =>
      _c.get(ApiEndpoints.labels, parse: (d) => _list(d).map(LabelModel.fromJson).toList());
  Future<ApiResponse<LabelModel>> createLabel(String name, int color) =>
      _c.post(ApiEndpoints.labelCreate, body: {'name': name, 'color': color}, parse: (d) => LabelModel.fromJson(_map(d)));
  Future<ApiResponse<LabelModel>> updateLabel(String id, String name, int color) => _c.post(
      ApiEndpoints.labelUpdate,
      body: {'id': id, 'name': name, 'color': color},
      parse: (d) => LabelModel.fromJson(_map(d)));
  Future<ApiResponse<void>> deleteLabel(String id) => _c.post<void>(ApiEndpoints.labelDelete, body: {'id': id});
  Future<ApiResponse<void>> assignLabel(List<String> emailIds, String labelId, bool add) =>
      _c.post<void>(ApiEndpoints.labelAssign, body: {'ids': emailIds, 'label_id': labelId, 'add': add});

  // ---------- Contacts ----------
  Future<ApiResponse<List<ContactModel>>> contacts() =>
      _c.get(ApiEndpoints.contacts, parse: (d) => _list(d).map(ContactModel.fromJson).toList());
  Future<ApiResponse<ContactModel>> createContact(ContactModel c) =>
      _c.post(ApiEndpoints.contactCreate, body: c.toJson(), parse: (d) => ContactModel.fromJson(_map(d)));
  Future<ApiResponse<ContactModel>> updateContact(ContactModel c) =>
      _c.post(ApiEndpoints.contactUpdate, body: c.toJson(), parse: (d) => ContactModel.fromJson(_map(d)));
  Future<ApiResponse<void>> deleteContact(String id) => _c.post<void>(ApiEndpoints.contactDelete, body: {'id': id});

  // ---------- Notifications / devices / storage ----------
  Future<ApiResponse<List<NotificationModel>>> notifications() =>
      _c.get(ApiEndpoints.notifications, parse: (d) => _list(d).map(NotificationModel.fromJson).toList());
  Future<ApiResponse<void>> markNotificationsRead(List<String> ids) =>
      _c.post<void>(ApiEndpoints.notificationsMarkRead, body: {'ids': ids});
  Future<ApiResponse<void>> registerDevice(String token, String platform, String name) => _c.post<void>(
      ApiEndpoints.registerDevice,
      body: {'push_token': token, 'platform': platform, 'device_name': name});
  Future<ApiResponse<void>> savePrefs(Map<String, dynamic> prefs) =>
      _c.post<void>(ApiEndpoints.notificationPrefs, body: prefs);

  Future<ApiResponse<List<Map<String, dynamic>>>> devices() => _c.get(ApiEndpoints.devices, parse: _list);
  Future<ApiResponse<void>> revokeDevice(String id) => _c.post<void>(ApiEndpoints.deviceRevoke, body: {'id': id});
  Future<ApiResponse<List<Map<String, dynamic>>>> loginHistory() => _c.get(ApiEndpoints.loginHistory, parse: _list);

  Future<ApiResponse<StorageModel>> storage() =>
      _c.get(ApiEndpoints.storageUsage, parse: (d) => StorageModel.fromJson(_map(d)));
  Future<ApiResponse<List<AttachmentModel>>> storageAttachments() => _c.get(ApiEndpoints.storageQuota,
      query: {'include': 'attachments'}, parse: (d) => _list(_map(d)['attachments']).map(AttachmentModel.fromJson).toList());
}
