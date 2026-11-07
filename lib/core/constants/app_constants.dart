class AppConstants {
  AppConstants._();

  static const String fontFamily = 'Roboto';
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double tabletBreakpoint = 720;
  static const String systemFolderPrefix = 'system:';
}

/// Identifiers for built-in mailboxes. Match the planned backend folder keys.
class FolderIds {
  FolderIds._();
  static const inbox = 'inbox';
  static const starred = 'starred';
  static const snoozed = 'snoozed';
  static const sent = 'sent';
  static const drafts = 'drafts';
  static const scheduled = 'scheduled';
  static const important = 'important';
  static const allMail = 'all';
  static const spam = 'spam';
  static const trash = 'trash';
}
