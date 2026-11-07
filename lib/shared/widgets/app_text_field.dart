import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? suffixText;
  final IconData? prefixIcon;
  final TextInputAction? action;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? formatters;
  final int? maxLines;
  final bool autofocus;
  final String? errorText;
  final String? helper;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboard,
    this.validator,
    this.suffix,
    this.suffixText,
    this.prefixIcon,
    this.action,
    this.onChanged,
    this.onSubmitted,
    this.formatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.errorText,
    this.helper,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboard,
      textInputAction: widget.action,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: widget.formatters,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      autocorrect: !widget.obscure && widget.keyboard != TextInputType.emailAddress,
      enableSuggestions: !widget.obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
        suffixText: widget.suffixText,
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: () => setState(() => _hidden = !_hidden),
                tooltip: _hidden ? 'Show password' : 'Hide password',
              )
            : widget.suffix,
      ),
    );
  }
}
