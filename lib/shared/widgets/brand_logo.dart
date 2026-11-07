import 'package:flutter/material.dart';

/// Uses the provided A-Mail logo assets.
class BrandMark extends StatelessWidget {
  final double height;
  const BrandMark({super.key, this.height = 40});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/logo/a_mail_mark.png', height: height, fit: BoxFit.contain, filterQuality: FilterQuality.high);
}

class BrandWordmark extends StatelessWidget {
  final double height;
  const BrandWordmark({super.key, this.height = 28});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final img = Image.asset('assets/logo/a_mail_wordmark.png', height: height, fit: BoxFit.contain, filterQuality: FilterQuality.high);
    // The wordmark is navy ink; lighten it on dark backgrounds so it stays legible.
    return dark ? ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFE9EDFA), BlendMode.srcATop), child: img) : img;
  }
}

class BrandLockup extends StatelessWidget {
  final double markHeight;
  const BrandLockup({super.key, this.markHeight = 88});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        BrandMark(height: markHeight),
        SizedBox(height: markHeight * 0.16),
        BrandWordmark(height: markHeight * 0.30),
      ]);
}
