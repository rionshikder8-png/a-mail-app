import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/html_utils.dart';
import '../../models/email_model.dart';
import '../../providers/auth_provider.dart';
import 'compose_screen.dart';

class ReplyArgs {
  final EmailModel original;
  final bool replyAll;
  const ReplyArgs(this.original, this.replyAll);
}

class ReplyScreen extends StatelessWidget {
  final EmailModel original;
  final bool replyAll;
  const ReplyScreen({super.key, required this.original, this.replyAll = false});

  static String quoted(EmailModel e) {
    final body = e.bodyText.isNotEmpty ? e.bodyText : HtmlUtils.toPlain(e.bodyHtml);
    final q = body.split('\n').map((l) => '> $l').join('\n');
    return '\n\nOn ${DateFmt.full(e.date)}, ${e.from.display} <${e.from.address}> wrote:\n$q';
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user?.address.toLowerCase() ?? '';
    final to = <EmailAddress>[original.from];
    final cc = <EmailAddress>[];
    if (replyAll) {
      for (final a in [...original.to, ...original.cc]) {
        if (a.address.toLowerCase() != me && !to.contains(a)) cc.add(a);
      }
    }
    final subj = original.subject.toLowerCase().startsWith('re:') ? original.subject : 'Re: ${original.subject}';
    return ComposeScreen(
      title: replyAll ? 'Reply all' : 'Reply',
      prefilledTo: to,
      prefilledCc: cc,
      initialSubject: subj,
      initialBody: quoted(original),
      inReplyToId: original.id,
      threadId: original.threadId,
    );
  }
}
