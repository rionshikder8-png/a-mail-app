import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../models/email_model.dart';

/// SQLite cache for offline reading. Only stores what the server returned for
/// the signed-in user; wiped on sign-out.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'a_mail_cache.db');
    _db = await openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('''
        CREATE TABLE emails(
          id TEXT PRIMARY KEY,
          folder TEXT NOT NULL,
          date INTEGER NOT NULL,
          json TEXT NOT NULL
        )''');
      await d.execute('CREATE INDEX idx_emails_folder_date ON emails(folder, date DESC)');
      await d.execute('''
        CREATE TABLE outbox(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kind TEXT NOT NULL,
          payload TEXT NOT NULL,
          created INTEGER NOT NULL
        )''');
      await d.execute('''
        CREATE TABLE drafts(
          id TEXT PRIMARY KEY,
          updated INTEGER NOT NULL,
          json TEXT NOT NULL
        )''');
    });
    return _db!;
  }

  Future<void> cacheEmails(String folder, List<EmailModel> emails, {bool replace = false}) async {
    final d = await db;
    final b = d.batch();
    if (replace) b.delete('emails', where: 'folder = ?', whereArgs: [folder]);
    for (final e in emails) {
      b.insert(
        'emails',
        {'id': e.id, 'folder': folder, 'date': e.date.millisecondsSinceEpoch, 'json': jsonEncode(e.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await b.commit(noResult: true);
  }

  Future<List<EmailModel>> cachedEmails(String folder, {int limit = 50}) async {
    final d = await db;
    final rows = await d.query('emails',
        where: 'folder = ?', whereArgs: [folder], orderBy: 'date DESC', limit: limit);
    return rows
        .map((r) => EmailModel.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeEmail(String id) async =>
      (await db).delete('emails', where: 'id = ?', whereArgs: [id]);

  // Outbox (queued actions while offline)
  Future<int> enqueue(String kind, Map<String, dynamic> payload) async => (await db).insert(
      'outbox', {'kind': kind, 'payload': jsonEncode(payload), 'created': DateTime.now().millisecondsSinceEpoch});

  Future<List<Map<String, dynamic>>> pendingOutbox() async => (await db).query('outbox', orderBy: 'id ASC');

  Future<void> removeOutbox(int id) async => (await db).delete('outbox', where: 'id = ?', whereArgs: [id]);

  // Local drafts
  Future<void> saveDraft(String id, Map<String, dynamic> json) async => (await db).insert(
      'drafts', {'id': id, 'updated': DateTime.now().millisecondsSinceEpoch, 'json': jsonEncode(json)},
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Map<String, dynamic>>> localDrafts() async {
    final rows = await (await db).query('drafts', orderBy: 'updated DESC');
    return rows.map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>).toList();
  }

  Future<void> deleteDraft(String id) async => (await db).delete('drafts', where: 'id = ?', whereArgs: [id]);

  Future<void> wipe() async {
    final d = await db;
    await d.delete('emails');
    await d.delete('outbox');
    await d.delete('drafts');
  }
}
