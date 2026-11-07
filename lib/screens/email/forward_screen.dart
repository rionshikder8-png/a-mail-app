import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/html_utils.dart';
import '../../models/email_model.dart';
import 'compose_screen.dart';

class ForwardScreen extends StatelessWidget {
  final EmailModel original;
  const ForwardScreen({super.key, required this.original});

  @override
  Widget build(BuildContext context) {
    final body = original.bodyText.isNotEmpty ? original.bodyText : HtmlUtils.toPlain(original.bodyHtml);
    final subj = original.subject.toLowerCase().startsWith('fwd:') ? original.subject : 'Fwd: ${original.subject}';
    final header = '\n\n---------- Forwarded message ----------\n'
        'From: ${original.from.display} <${original.from.address}>\n'
        'Date: ${DateFmt.full(original.date)}\n'
        'Subject: ${original.subject}\n'
        'To: ${original.to.map((e) => e.address).join(', ')}\n\n$body';
    return ComposeScreen(
      title: 'Forward',
      initialSubject: subj,
      initialBody: header,
      threadId: original.threadId,
      initialAttachments: original.attachments,
    );
  }
}
