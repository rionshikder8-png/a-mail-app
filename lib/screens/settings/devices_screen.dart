import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/misc_repository.dart';
import '../../providers/email_provider.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/state_views.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _history = [];
  LoadState _state = LoadState.loading;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    final d = await MiscRepository.instance.devices();
    final h = await MiscRepository.instance.loginHistory();
    if (!mounted) return;
    setState(() {
      if (d.ok) {
        _devices = d.data ?? [];
        _history = h.data ?? [];
        _state = LoadState.loaded;
      } else {
        _error = d.error!.message;
        _offline = d.error!.isOffline || d.error!.isNotConfigured;
        _state = LoadState.error;
      }
    });
  }

  Future<void> _revoke(Map<String, dynamic> d) async {
    final ok = await confirmDialog(context, title: 'Sign out device?', message: '${d['device_name'] ?? 'This device'} will be signed out of A-Mail.', confirmLabel: 'Sign out', destructive: true);
    if (!ok) return;
    final r = await MiscRepository.instance.revokeDevice('${d['id']}');
    if (!mounted) return;
    if (r.ok) {
      setState(() => _devices.remove(d));
      context.toast('Device signed out');
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices & activity'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Devices'), Tab(text: 'Login history')]),
      ),
      body: switch (_state) {
        LoadState.loading || LoadState.idle => const ListSkeleton(count: 4),
        LoadState.error => StateView(icon: _offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded, title: 'Couldn\'t load', message: _error ?? '', actionLabel: 'Retry', onAction: _load),
        _ => TabBarView(controller: _tabs, children: [
            _devices.isEmpty
                ? StateView.empty(icon: Icons.devices_other_rounded, title: 'No devices', message: 'Signed-in devices will be listed here.')
                : ListView(children: [
                    for (final d in _devices)
                      ListTile(
                        leading: Icon('${d['platform']}' == 'ios' ? Icons.phone_iphone_rounded : Icons.phone_android_rounded),
                        title: Text('${d['device_name'] ?? 'Unknown device'}'),
                        subtitle: Text('${d['current'] == true ? 'This device · ' : ''}Last active ${d['last_active'] != null ? DateFmt.relative(DateTime.tryParse('${d['last_active']}') ?? DateTime.now()) : 'unknown'}'),
                        trailing: d['current'] == true ? null : IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Sign out', onPressed: () => _revoke(d)),
                      ),
                  ]),
            _history.isEmpty
                ? StateView.empty(icon: Icons.history_rounded, title: 'No history', message: 'Recent sign-ins will appear here.')
                : ListView(children: [
                    for (final h in _history)
                      ListTile(
                        leading: Icon(h['success'] == false ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: h['success'] == false ? context.colors.error : null),
                        title: Text('${h['device_name'] ?? 'Unknown device'}'),
                        subtitle: Text('${h['ip'] ?? ''} · ${h['created_at'] != null ? DateFmt.short(DateTime.tryParse('${h['created_at']}') ?? DateTime.now()) : ''}'),
                      ),
                  ]),
          ]),
      },
    );
  }
}
