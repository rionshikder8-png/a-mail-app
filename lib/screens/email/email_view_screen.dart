import 'package:flutter/material.dart';
import '../../models/email_model.dart';
import '../inbox/email_thread_screen.dart';

/// Single-message reader. Delegates to the conversation view so a message
/// always opens with its thread, matching Gmail's behaviour.
class EmailViewScreen extends StatelessWidget {
  final String emailId;
  final EmailModel? initial;
  const EmailViewScreen({super.key, required this.emailId, this.initial});

  @override
  Widget build(BuildContext context) => EmailThreadScreen(emailId: emailId, initial: initial);
}
