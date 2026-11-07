import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';

/// Six-box one-time-code input that supports paste.
class OtpField extends StatefulWidget {
  final void Function(String code) onChanged;
  final void Function(String code)? onCompleted;
  final bool hasError;
  const OtpField({super.key, required this.onChanged, this.onCompleted, this.hasError = false});

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void clear() {
    _c.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = AppConfig.otpLength;
    return GestureDetector(
      onTap: () => _f.requestFocus(),
      child: Stack(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(n, (i) {
            final filled = i < _c.text.length;
            final active = _f.hasFocus && i == _c.text.length.clamp(0, n - 1);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 48,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.hasError ? cs.error : (active ? cs.primary : cs.outlineVariant),
                  width: active || widget.hasError ? 1.8 : 1,
                ),
              ),
              child: Text(filled ? _c.text[i] : '', style: Theme.of(context).textTheme.headlineSmall),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _c,
              focusNode: _f,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(n)],
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
                if (v.length == n) widget.onCompleted?.call(v);
              },
              enableInteractiveSelection: false,
            ),
          ),
        ),
      ]),
    );
  }
}
