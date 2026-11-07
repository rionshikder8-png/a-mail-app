import 'package:flutter/material.dart';
import '../../shared/dialogs/dialogs.dart';

/// Controller wrapping a TextEditingController with formatting commands that
/// insert lightweight markup (see RichTextCodec). Formatting is applied to the
/// current selection, or inserted as a placeholder pair at the cursor.
class RichTextController extends TextEditingController {
  RichTextController({super.text});

  void _wrap(String open, String close, String placeholder) {
    final sel = selection;
    final t = text;
    if (!sel.isValid) {
      text = '$t$open$placeholder$close';
      selection = TextSelection.collapsed(offset: text.length - close.length);
      return;
    }
    final s = sel.start, e = sel.end;
    final inner = s == e ? placeholder : t.substring(s, e);
    final nt = t.replaceRange(s, e, '$open$inner$close');
    value = TextEditingValue(
      text: nt,
      selection: s == e
          ? TextSelection(baseOffset: s + open.length, extentOffset: s + open.length + placeholder.length)
          : TextSelection.collapsed(offset: s + open.length + inner.length + close.length),
    );
  }

  void bold() => _wrap('**', '**', 'bold text');
  void italic() => _wrap('__', '__', 'italic text');
  void underline() => _wrap('++', '++', 'underlined text');

  void _prefixLines(String Function(int i) prefix) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final t = text;
    final start = t.lastIndexOf('\n', (sel.start - 1).clamp(0, t.length)) + 1;
    final endIdx = t.indexOf('\n', sel.end);
    final end = endIdx == -1 ? t.length : endIdx;
    final lines = t.substring(start, end).split('\n');
    final out = [for (var i = 0; i < lines.length; i++) '${prefix(i)}${lines[i].replaceFirst(RegExp(r'^(• |\d+\. )'), '')}'];
    final nt = t.replaceRange(start, end, out.join('\n'));
    value = TextEditingValue(text: nt, selection: TextSelection.collapsed(offset: start + out.join('\n').length));
  }

  void bulletList() => _prefixLines((_) => '• ');
  void numberedList() => _prefixLines((i) => '${i + 1}. ');

  void insertLink(String label, String url) {
    final md = '[${label.isEmpty ? url : label}]($url)';
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final nt = text.replaceRange(sel.start, sel.end, md);
    value = TextEditingValue(text: nt, selection: TextSelection.collapsed(offset: sel.start + md.length));
  }

  String get selectedText => selection.isValid && !selection.isCollapsed ? text.substring(selection.start, selection.end) : '';
}

class RichTextToolbar extends StatelessWidget {
  final RichTextController controller;
  final VoidCallback onAttach;
  final VoidCallback onImage;
  const RichTextToolbar({super.key, required this.controller, required this.onAttach, required this.onImage});

  Future<void> _link(BuildContext context) async {
    final label = controller.selectedText;
    final url = await promptDialog(context, title: 'Insert link', hint: 'https://example.com', confirmLabel: 'Insert');
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Links must start with http:// or https://')));
      }
      return;
    }
    controller.insertLink(label, url);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget b(IconData i, String tip, VoidCallback f) => IconButton(
          icon: Icon(i, size: 22),
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          onPressed: f,
        );
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          b(Icons.format_bold_rounded, 'Bold', controller.bold),
          b(Icons.format_italic_rounded, 'Italic', controller.italic),
          b(Icons.format_underlined_rounded, 'Underline', controller.underline),
          SizedBox(height: 22, child: VerticalDivider(color: cs.outlineVariant)),
          b(Icons.format_list_bulleted_rounded, 'Bulleted list', controller.bulletList),
          b(Icons.format_list_numbered_rounded, 'Numbered list', controller.numberedList),
          b(Icons.link_rounded, 'Insert link', () => _link(context)),
          SizedBox(height: 22, child: VerticalDivider(color: cs.outlineVariant)),
          b(Icons.attach_file_rounded, 'Attach file', onAttach),
          b(Icons.image_outlined, 'Insert image', onImage),
        ]),
      ),
    );
  }
}
