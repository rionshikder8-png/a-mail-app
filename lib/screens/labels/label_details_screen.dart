import 'package:flutter/material.dart';
import '../inbox/inbox_list.dart';

class LabelDetailsScreen extends StatelessWidget {
  final String labelId;
  final String name;
  const LabelDetailsScreen({super.key, required this.labelId, required this.name});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: InboxList(
          folder: 'all',
          labelId: labelId,
          emptyIcon: Icons.label_outline_rounded,
          emptyTitle: 'Nothing labelled "$name"',
          emptyMessage: 'Apply this label to a message from the message menu.',
        ),
      );
}
