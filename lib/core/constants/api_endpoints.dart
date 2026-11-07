/// Endpoint paths relative to `ApiConfig.apiRoot`. Names mirror the planned
/// a-mail-backend REST API (api/auth/login.php -> /auth/login, etc.).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register = '/auth/register';
  static const usernameAvailable = '/auth/username-available';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const refreshToken = '/auth/refresh-token';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const verifyOtp = '/auth/verify-otp';
  static const twoFactor = '/auth/two-factor';

  // Users
  static const profile = '/users/profile';
  static const updateProfile = '/users/update-profile';
  static const changePassword = '/users/change-password';
  static const accountSettings = '/users/account-settings';
  static const deleteAccount = '/users/delete-account';

  // Emails
  static const inbox = '/emails/inbox';
  static const viewEmail = '/emails/view';
  static const sendEmail = '/emails/send';
  static const reply = '/emails/reply';
  static const forward = '/emails/forward';
  static const drafts = '/emails/drafts';
  static const saveDraft = '/emails/save-draft';
  static const sent = '/emails/sent';
  static const search = '/emails/search';
  static const archive = '/emails/archive';
  static const delete = '/emails/delete';
  static const restore = '/emails/restore';
  static const star = '/emails/star';
  static const markRead = '/emails/mark-read';
  static const snooze = '/emails/snooze';
  static const schedule = '/emails/schedule';

  // Folders
  static const starred = '/folders/starred';
  static const important = '/folders/important';
  static const allMail = '/folders/all-mail';
  static const spam = '/folders/spam';
  static const trash = '/folders/trash';
  static const scheduled = '/folders/scheduled';

  // Labels
  static const labels = '/labels/list';
  static const labelCreate = '/labels/create';
  static const labelUpdate = '/labels/update';
  static const labelDelete = '/labels/delete';
  static const labelAssign = '/labels/assign';

  // Attachments
  static const attachmentUpload = '/attachments/upload';
  static const attachmentDownload = '/attachments/download';
  static const attachmentDelete = '/attachments/delete';

  // Contacts
  static const contacts = '/contacts/list';
  static const contactCreate = '/contacts/create';
  static const contactUpdate = '/contacts/update';
  static const contactDelete = '/contacts/delete';

  // Notifications
  static const notifications = '/notifications/list';
  static const notificationsMarkRead = '/notifications/mark-read';
  static const registerDevice = '/notifications/register-device';
  static const notificationPrefs = '/notifications/preferences';

  // Devices
  static const devices = '/devices/list';
  static const deviceRevoke = '/devices/revoke';
  static const loginHistory = '/devices/login-history';

  // Storage
  static const storageUsage = '/storage/usage';
  static const storageQuota = '/storage/quota';
}
