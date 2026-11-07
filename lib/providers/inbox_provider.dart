import 'package:flutter/material.dart';
import '../core/network/api_response.dart';
import '../data/repositories/email_repository.dart';
import '../models/email_model.dart';
import 'email_provider.dart';

/// Inbox filter chips + search state.
enum InboxFilter { all, unread, starred, attachments }

class SearchQuery {
  String text = '';
  String from = '';
  String to = '';
  String subject = '';
  bool hasAttachment = false;
  DateTime? after;
  DateTime? before;
  String folder = 'all';

  bool get isEmpty =>
      text.isEmpty && from.isEmpty && to.isEmpty && subject.isEmpty && !hasAttachment && after == null && before == null;

  Map<String, dynamic> toParams() => {
        if (text.isNotEmpty) 'q': text,
        if (from.isNotEmpty) 'from': from,
        if (to.isNotEmpty) 'to': to,
        if (subject.isNotEmpty) 'subject': subject,
        if (hasAttachment) 'has_attachment': 1,
        if (after != null) 'after': after!.toIso8601String(),
        if (before != null) 'before': before!.toIso8601String(),
        'folder': folder,
      };
}

class InboxProvider extends ChangeNotifier {
  InboxFilter filter = InboxFilter.all;

  void setFilter(InboxFilter f) {
    filter = f;
    notifyListeners();
  }

  List<EmailModel> apply(List<EmailModel> src) {
    switch (filter) {
      case InboxFilter.unread:
        return src.where((e) => !e.isRead).toList();
      case InboxFilter.starred:
        return src.where((e) => e.isStarred).toList();
      case InboxFilter.attachments:
        return src.where((e) => e.hasAttachments).toList();
      case InboxFilter.all:
        return src;
    }
  }

  // ---- search ----
  final SearchQuery query = SearchQuery();
  LoadState searchState = LoadState.idle;
  List<EmailModel> results = [];
  ApiError? searchError;
  final List<String> recent = [];

  Future<void> search() async {
    if (query.isEmpty) {
      results = [];
      searchState = LoadState.idle;
      notifyListeners();
      return;
    }
    searchState = LoadState.loading;
    notifyListeners();
    final r = await EmailRepository.instance.search(query.toParams());
    if (r.ok) {
      results = r.data ?? [];
      searchState = results.isEmpty ? LoadState.empty : LoadState.loaded;
      if (query.text.isNotEmpty) {
        recent.remove(query.text);
        recent.insert(0, query.text);
        if (recent.length > 8) recent.removeLast();
      }
    } else {
      searchError = r.error;
      searchState = LoadState.error;
    }
    notifyListeners();
  }

  void clearSearch() {
    query
      ..text = ''
      ..from = ''
      ..to = ''
      ..subject = ''
      ..hasAttachment = false
      ..after = null
      ..before = null
      ..folder = 'all';
    results = [];
    searchState = LoadState.idle;
    notifyListeners();
  }
}
