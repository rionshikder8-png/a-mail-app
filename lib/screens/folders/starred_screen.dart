import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class StarredScreen extends StatelessWidget {
  const StarredScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'starred',
        title: 'Starred',
        emptyIcon: Icons.star_outline_rounded,
        emptyTitle: 'No starred messages',
        emptyMessage: 'Star important messages to find them here quickly.',
      );
}
