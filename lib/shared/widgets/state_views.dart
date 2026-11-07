import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/network/api_response.dart';

/// Reusable empty / error / offline / loading presentations.
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  factory StateView.empty({Key? key, required IconData icon, required String title, required String message}) =>
      StateView(key: key, icon: icon, title: title, message: message);

  /// Chooses the right copy for the error type.
  factory StateView.error(ApiError e, {Key? key, VoidCallback? onRetry}) {
    if (e.isNotConfigured) {
      return StateView(
        key: key,
        icon: Icons.cloud_off_rounded,
        title: 'Server not connected',
        message:
            'A-Mail can\'t reach its mail service yet. Once the backend is live and the server address is set, your mail will appear here.',
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }
    if (e.isOffline) {
      return StateView(
        key: key,
        icon: Icons.wifi_off_rounded,
        title: 'You\'re offline',
        message: e.message,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }
    return StateView(
      key: key,
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: e.message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: tt.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(140, 44)),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerLow,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(radius: 20, backgroundColor: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: 140, decoration: _b()),
                const SizedBox(height: 8),
                Container(height: 12, decoration: _b()),
                const SizedBox(height: 6),
                Container(height: 10, width: 220, decoration: _b()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  BoxDecoration _b() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6));
}

class OfflineBanner extends StatelessWidget {
  final String message;
  const OfflineBanner({super.key, this.message = 'Offline. Showing saved mail.'});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(Icons.cloud_off_rounded, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}
