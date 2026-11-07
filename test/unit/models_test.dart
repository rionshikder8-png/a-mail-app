import 'package:a_mail/core/helpers/address_parser.dart';
import 'package:a_mail/core/network/api_response.dart';
import 'package:a_mail/core/utils/date_utils.dart';
import 'package:a_mail/models/attachment_model.dart';
import 'package:a_mail/models/email_model.dart';
import 'package:a_mail/models/storage_model.dart';
import 'package:a_mail/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmailModel JSON round-trip', () {
    final json = {
      'id': 7,
      'thread_id': 't1',
      'from': {'name': 'Ann', 'address': 'ann@x.com'},
      'to': [
        {'name': '', 'address': 'me@adverune.store'}
      ],
      'subject': 'Hi',
      'snippet': 's',
      'body_text': 'b',
      'date': '2026-01-02T03:04:05Z',
      'is_read': 1,
      'is_starred': true,
      'attachments': [
        {'id': 1, 'file_name': 'a.pdf', 'mime_type': 'application/pdf', 'size_bytes': 2048}
      ],
    };
    final e = EmailModel.fromJson(json);
    expect(e.id, '7');
    expect(e.isRead, isTrue);
    expect(e.isStarred, isTrue);
    expect(e.hasAttachments, isTrue);
    final again = EmailModel.fromJson(e.toJson());
    expect(again.subject, 'Hi');
    expect(again.attachments.first.fileName, 'a.pdf');
  });

  test('EmailModel.copyWith keeps identity', () {
    final e = EmailModel(id: '1', threadId: '1', from: const EmailAddress(address: 'a@b.c'), subject: 's', date: DateTime(2026));
    final r = e.copyWith(isRead: true, isStarred: true);
    expect(r.id, '1');
    expect(r.isRead && r.isStarred, isTrue);
    expect(e.isRead, isFalse);
  });

  test('EmailAddress equality is case-insensitive', () {
    expect(const EmailAddress(address: 'A@B.com') == const EmailAddress(address: 'a@b.COM'), isTrue);
  });

  test('UserModel address + initials', () {
    const u = UserModel(id: '1', username: 'rion', displayName: 'Rion Shikder');
    expect(u.address, 'rion@adverune.store');
    expect(u.initials, 'RS');
  });

  test('Attachment size labels', () {
    expect(const AttachmentModel(id: '1', fileName: 'a', mimeType: 'x', sizeBytes: 500).sizeLabel, '500 B');
    expect(const AttachmentModel(id: '1', fileName: 'a', mimeType: 'x', sizeBytes: 2048).sizeLabel, '2 KB');
    expect(const AttachmentModel(id: '1', fileName: 'a', mimeType: 'x', sizeBytes: 5 * 1024 * 1024).sizeLabel, '5.0 MB');
  });

  test('Storage fraction clamps', () {
    expect(const StorageModel(usedBytes: 50, quotaBytes: 100).fraction, 0.5);
    expect(const StorageModel(usedBytes: 500, quotaBytes: 100).fraction, 1.0);
    expect(const StorageModel(usedBytes: 5, quotaBytes: 0).fraction, 0);
  });

  test('AddressParser', () {
    final l = AddressParser.parse('Ann <ann@x.com>, bob@y.io; "Cy" <c@z.org>');
    expect(l.length, 3);
    expect(l[0].name, 'Ann');
    expect(l[1].address, 'bob@y.io');
    expect(l[2].name, 'Cy');
    expect(AddressParser.allValid(l), isTrue);
    expect(AddressParser.allValid(AddressParser.parse('bad')), isFalse);
  });

  test('DateFmt list format', () {
    final now = DateTime(2026, 6, 15, 12);
    expect(DateFmt.list(DateTime(2026, 6, 15, 9, 30), now: now), '9:30 AM');
    expect(DateFmt.list(DateTime(2026, 3, 2), now: now), 'Mar 2');
    expect(DateFmt.list(DateTime(2024, 3, 2), now: now), '02/03/24');
    expect(DateFmt.dayHeader(DateTime(2026, 6, 14), now: now), 'Yesterday');
  });

  test('ApiResponse mapping + error flags', () {
    final ok = ApiResponse<int>.success(2).map((v) => v * 3);
    expect(ok.ok && ok.data == 6, isTrue);
    final bad = ApiResponse<int>.failure(const ApiError(code: 'offline', message: 'x'));
    expect(bad.ok, isFalse);
    expect(bad.error!.isOffline, isTrue);
    expect(bad.map((v) => v).error!.code, 'offline');
  });
}
