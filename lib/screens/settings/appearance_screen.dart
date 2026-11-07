import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/components/settings_tiles.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final s = context.watch<SettingsProvider>();
    String swipeLabel(SwipeAction a) => switch (a) { SwipeAction.archive => 'Archive', SwipeAction.delete => 'Delete', SwipeAction.none => 'None' };

    Future<void> pickSwipe(bool right) async {
      final cur = right ? s.swipeRight : s.swipeLeft;
      final v = await showModalBottomSheet<SwipeAction>(
        context: context,
        builder: (c) => SafeArea(
          child: RadioGroup<SwipeAction>(
            groupValue: cur,
            onChanged: (v) => Navigator.pop(c, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final a in SwipeAction.values) RadioListTile<SwipeAction>(value: a, title: Text(swipeLabel(a))),
            ]),
          ),
        ),
      );
      if (v != null) right ? s.setSwipe(right: v) : s.setSwipe(left: v);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('System')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
            ],
            selected: {theme.mode},
            onSelectionChanged: (v) => theme.setMode(v.first),
          ),
        ),
        SettingsSection(title: 'Inbox', children: [
          SettingsSwitch(icon: Icons.density_small_rounded, title: 'Compact list', subtitle: 'Show more messages on screen', value: s.compactDensity, onChanged: s.setDensity),
          SettingsTile(icon: Icons.swipe_right_alt_rounded, title: 'Swipe right', subtitle: swipeLabel(s.swipeRight), onTap: () => pickSwipe(true)),
          SettingsTile(icon: Icons.swipe_left_alt_rounded, title: 'Swipe left', subtitle: swipeLabel(s.swipeLeft), onTap: () => pickSwipe(false)),
        ]),
      ]),
    );
  }
}
