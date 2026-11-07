/// Minimal, dependency-free HTML → readable text conversion for email bodies.
/// We deliberately do not render remote HTML in a WebView (no tracking pixels,
/// no scripts); the text view keeps structure (paragraphs, lists, links).
class HtmlUtils {
  HtmlUtils._();

  static String toPlain(String html) {
    var s = html;
    s = s.replaceAll(RegExp(r'<(script|style)[\s\S]*?</\1>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</(p|div|h[1-6]|tr|blockquote)>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    s = s.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    s = s.replaceAllMapped(
        RegExp(r'<a[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>', caseSensitive: false),
        (m) {
          final text = m.group(2)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
          final url = m.group(1)!;
          return (text.isEmpty || text == url) ? url : '$text ($url)';
        });
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = decodeEntities(s);
    s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String decodeEntities(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));

  static String escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  static String snippet(String html, {int max = 120}) {
    final t = toPlain(html).replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= max ? t : '${t.substring(0, max)}…';
  }
}
