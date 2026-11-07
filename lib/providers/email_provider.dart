import 'package:flutter/material.dart';
import '../core/network/api_response.dart';
import '../data/repositories/email_repository.dart';
import '../models/email_model.dart';

enum LoadState { idle, loading, loaded, empty, error }

/// Per-mailbox paged list state, selection mode and mutations.
class MailboxState {
  List<EmailModel> items = [];
  LoadState state = LoadState.idle;
  ApiError? error;
  bool hasMore = false;
  bool loadingMore = false;
  bool fromCache = false;
  int page = 1;
}

class EmailProvider extends ChangeNotifier {
  final _repo = EmailRepository.instance;
  final Map<String, MailboxState> _boxes = {};
  final Set<String> selected = {};

  MailboxState box(String folder, {String? labelId}) =>
      _boxes.putIfAbsent(_key(folder, labelId), () => MailboxState());

  String _key(String f, String? l) => l == null ? f : '$f#$l';

  bool get selecting => selected.isNotEmpty;

  Future<void> load(String folder, {String? labelId, bool refresh = false}) async {
    final b = box(folder, labelId: labelId);
    if (b.state == LoadState.loading) return;
    if (!refresh && (b.state == LoadState.loaded || b.state == LoadState.empty)) return;
    b.state = LoadState.loading;
    b.error = null;
    if (refresh) selected.clear();
    notifyListeners();
    final r = await _repo.loadFolder(folder, labelId: labelId);
    if (r.ok) {
      b.items = r.data!.emails;
      b.hasMore = r.data!.hasMore;
      b.fromCache = r.data!.fromCache;
      b.page = 1;
      b.state = b.items.isEmpty ? LoadState.empty : LoadState.loaded;
    } else {
      b.error = r.error;
      b.state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore(String folder, {String? labelId}) async {
    final b = box(folder, labelId: labelId);
    if (!b.hasMore || b.loadingMore || b.state != LoadState.loaded) return;
    b.loadingMore = true;
    notifyListeners();
    final r = await _repo.loadFolder(folder, page: b.page + 1, labelId: labelId);
    if (r.ok) {
      b.page++;
      b.items = [...b.items, ...r.data!.emails];
      b.hasMore = r.data!.hasMore;
    }
    b.loadingMore = false;
    notifyListeners();
  }

  int unreadCount(String folder) => _boxes[folder]?.items.where((e) => !e.isRead).length ?? 0;

  // ----- selection -----
  void toggleSelect(String id) {
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    notifyListeners();
  }

  void selectAll(String folder, {String? labelId}) {
    selected
      ..clear()
      ..addAll(box(folder, labelId: labelId).items.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    selected.clear();
    notifyListeners();
  }

  // ----- optimistic mutations -----
  void _patch(Iterable<String> ids, EmailModel Function(EmailModel) f) {
    final s = ids.toSet();
    for (final b in _boxes.values) {
      b.items = [for (final e in b.items) s.contains(e.id) ? f(e) : e];
    }
  }

  void _remove(Iterable<String> ids) {
    final s = ids.toSet();
    for (final b in _boxes.values) {
      b.items = b.items.where((e) => !s.contains(e.id)).toList();
      if (b.items.isEmpty && b.state == LoadState.loaded) b.state = LoadState.empty;
    }
    selected.removeAll(s);
  }

  List<EmailModel> _snapshot(Iterable<String> ids) {
    final s = ids.toSet();
    final seen = <String>{};
    return [
      for (final b in _boxes.values)
        for (final e in b.items)
          if (s.contains(e.id) && seen.add(e.id)) e
    ];
  }

  Future<ApiResponse<void>> _optimistic(
      Iterable<String> ids, void Function() apply, Future<ApiResponse<void>> Function() call) async {
    final backup = {for (final b in _boxes.entries) b.key: List<EmailModel>.from(b.value.items)};
    final sel = Set<String>.from(selected);
    apply();
    notifyListeners();
    final r = await call();
    if (!r.ok) {
      for (final e in backup.entries) {
        _boxes[e.key]!.items = e.value;
        if (e.value.isNotEmpty && _boxes[e.key]!.state == LoadState.empty) _boxes[e.key]!.state = LoadState.loaded;
      }
      selected
        ..clear()
        ..addAll(sel);
      notifyListeners();
    }
    return r;
  }

  Future<ApiResponse<void>> archive(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.archive(ids));
  Future<ApiResponse<void>> trash(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.trash(ids));
  Future<ApiResponse<void>> deleteForever(List<String> ids) =>
      _optimistic(ids, () => _remove(ids), () => _repo.deleteForever(ids));
  Future<ApiResponse<void>> markSpam(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.spam(ids));
  Future<ApiResponse<void>> notSpam(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.notSpam(ids));
  Future<ApiResponse<void>> restore(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.restore(ids));

  Future<ApiResponse<void>> setRead(List<String> ids, bool read) =>
      _optimistic(ids, () => _patch(ids, (e) => e.copyWith(isRead: read)), () => _repo.markRead(ids, read));

  Future<ApiResponse<void>> setStar(String id, bool value) =>
      _optimistic([id], () => _patch([id], (e) => e.copyWith(isStarred: value)), () => _repo.star([id], value));

  Future<ApiResponse<void>> setImportant(List<String> ids, bool value) =>
      _optimistic(ids, () => _patch(ids, (e) => e.copyWith(isImportant: value)), () => _repo.important(ids, value));

  Future<ApiResponse<void>> snooze(List<String> ids, DateTime until) =>
      _optimistic(ids, () => _remove(ids), () => _repo.snooze(ids, until));

  Future<ApiResponse<void>> unsnooze(List<String> ids) => _optimistic(ids, () => _remove(ids), () => _repo.unsnooze(ids));

  /// Undo helper: re-insert snapshot and tell the server to revert.
  Future<void> undoRemove(List<EmailModel> snapshot, String folder, Future<ApiResponse<void>> Function() revert) async {
    final b = box(folder);
    final ids = b.items.map((e) => e.id).toSet();
    b.items = [...b.items, ...snapshot.where((e) => !ids.contains(e.id))]..sort((a, b) => b.date.compareTo(a.date));
    if (b.items.isNotEmpty) b.state = LoadState.loaded;
    notifyListeners();
    await revert();
  }

  List<EmailModel> snapshotOf(Iterable<String> ids) => _snapshot(ids);

  void reset() {
    _boxes.clear();
    selected.clear();
    notifyListeners();
  }
}
