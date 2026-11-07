import 'html_utils.dart';

/// Lightweight markup used by the compose editor.
/// Markers: **bold**, _italic_ (via __), <u> underline as ++text++, links as [text](url),
/// list items start with "• " or "1. ". Converted to simple, safe HTML on send.
class RichTextCodec {
  RichTextCodec._();

  static String toHtml(String markup) {
    final lines = markup.split('\n');
    final out = StringBuffer();
    var inUl = false, inOl = false;
    void close() {
      if (inUl) out.write('</ul>');
      if (inOl) out.write('</ol>');
      inUl = inOl = false;
    }

    for (final raw in lines) {
      final bullet = RegExp(r'^\s*[•\-\*] (.*)$').firstMatch(raw);
      final number = RegExp(r'^\s*\d+\. (.*)$').firstMatch(raw);
      if (bullet != null) {
        if (!inUl) {
          close();
          out.write('<ul>');
          inUl = true;
        }
        out.write('<li>${_inline(bullet.group(1)!)}</li>');
      } else if (number != null) {
        if (!inOl) {
          close();
          out.write('<ol>');
          inOl = true;
        }
        out.write('<li>${_inline(number.group(1)!)}</li>');
      } else {
        close();
        out.write(raw.trim().isEmpty ? '<br>' : '<div>${_inline(raw)}</div>');
      }
    }
    close();
    return out.toString();
  }

  static String _inline(String s) {
    var t = HtmlUtils.escape(s);
    t = t.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<b>${m.group(1)}</b>');
    t = t.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => '<i>${m.group(1)}</i>');
    t = t.replaceAllMapped(RegExp(r'\+\+(.+?)\+\+'), (m) => '<u>${m.group(1)}</u>');
    t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\((https?://[^\s)]+)\)'),
        (m) => '<a href="${m.group(2)}">${m.group(1)}</a>');
    return t;
  }

  static String toPlain(String markup) => markup
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'\+\+(.+?)\+\+'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\((https?://[^\s)]+)\)'), (m) => '${m.group(1)} (${m.group(2)})');
}
