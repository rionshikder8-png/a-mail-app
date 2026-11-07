import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../models/notification_model.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../../providers/notification_provider.dart';
import '../../shared/widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationProvider>().load());
  }

  IconData _icon(NotificationModel n) => switch (n.type) {
        'new_email' => Icons.mail_outline_rounded,
        'security' => Icons.shield_outlined,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    final cs = context.colors;

    final body = switch (p.state) {
      LoadState.idle || LoadState.loading => const ListSkeleton(count: 6),
      LoadState.error => StateView.error(p.error!, onRetry: () => p.load()),
      LoadState.empty => StateView.empty(icon: Icons.notifications_none_rounded, title: 'No notifications', message: 'New mail and security alerts will be listed here.'),
      LoadState.loaded => RefreshIndicator(
          onRefresh: () => p.load(),
          child: ListView.separated(
            itemCount: p.items.length,
            separatorBuilder: (_, __) => Divider(indent: 72, color: cs.outlineVariant.withValues(alpha: 0.6)),
            itemBuilder: (_, i) {
              final n = p.items[i];
              return ListTile(
                tileColor: n.read ? null : cs.primary.withValues(alpha: 0.05),
                leading: CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.12), child: Icon(_icon(n), color: cs.primary, size: 20)),
                title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(DateFmt.relative(n.createdAt), style: context.text.bodySmall),
                onTap: () {
                  if (n.emailId != null) context.push(Routes.threadPath(n.emailId!));
                },
              );
            },
          ),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          if (p.unread > 0) TextButton(onPressed: p.markAllRead, child: const Text('Mark all read')),
          IconButton(icon: const Icon(Icons.tune_rounded), tooltip: 'Preferences', onPressed: () => context.push(Routes.notificationSettings)),
        ],
      ),
      body: body,
    );
  }
}
