import 'package:flutter/material.dart';
import '../storage/storage_manager_screen.dart';

/// Settings entry point for storage; delegates to the full manager.
class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});
  @override
  Widget build(BuildContext context) => const StorageManagerScreen();
}
