import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/route_names.dart';
import 'folder_scaffold.dart';

class DraftsScreen extends StatelessWidget {
  const DraftsScreen({super.key});
  @override
  Widget build(BuildContext context) => FolderScaffold(
        folder: 'drafts',
        title: 'Drafts',
        emptyIcon: Icons.insert_drive_file_outlined,
        emptyTitle: 'No drafts',
        emptyMessage: 'Messages you start writing are saved here automatically.',
        onOpen: (e) => context.push(Routes.compose, extra: e),
      );
}
