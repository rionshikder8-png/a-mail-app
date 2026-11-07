import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SenderAvatar extends StatelessWidget {
  final String name;
  final String seed;
  final double size;
  final bool selected;
  final String? imageUrl;

  const SenderAvatar({super.key, required this.name, String? seed, this.size = 40, this.selected = false, this.imageUrl})
      : seed = seed ?? name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: selected
          ? Container(
              key: const ValueKey('sel'),
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
              child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: size * 0.55),
            )
          : Container(
              key: const ValueKey('av'),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AColors.avatar(seed),
                image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
              ),
              child: imageUrl != null
                  ? null
                  : Text(letter,
                      style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w600)),
            ),
    );
  }
}
