import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/attachment_model.dart';
import '../config/app_config.dart';

class FileService {
  FileService._();
  static final FileService instance = FileService._();

  /// Lets the user choose files. Enforces the per-file size limit.
  Future<({List<AttachmentModel> files, List<String> rejected})> pickAttachments({bool imagesOnly = false}) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: imagesOnly ? FileType.image : FileType.any,
    );
    final ok = <AttachmentModel>[];
    final bad = <String>[];
    if (res == null) return (files: ok, rejected: bad);
    for (final f in res.files) {
      if (f.path == null) continue;
      if (f.size > AppConfig.maxAttachmentBytes) {
        bad.add(f.name);
        continue;
      }
      ok.add(AttachmentModel(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}-${ok.length}',
        fileName: f.name,
        mimeType: _mime(f.extension),
        sizeBytes: f.size,
        localPath: f.path,
      ));
    }
    return (files: ok, rejected: bad);
  }

  Future<Directory> downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/downloads');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<List<FileSystemEntity>> downloadedFiles() async {
    final d = await downloadsDir();
    final l = d.listSync().whereType<File>().toList();
    l.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return l;
  }

  Future<int> downloadsSize() async {
    var t = 0;
    for (final f in await downloadedFiles()) {
      t += (f as File).lengthSync();
    }
    return t;
  }

  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<void> clearDownloads() async {
    for (final f in await downloadedFiles()) {
      await f.delete();
    }
  }

  Future<void> share(String path, {String? text}) =>
      Share.shareXFiles([XFile(path)], text: text);

  String _mime(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
