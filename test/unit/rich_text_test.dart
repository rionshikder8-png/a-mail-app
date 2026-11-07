import 'package:a_mail/core/utils/html_utils.dart';
import 'package:a_mail/core/utils/rich_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RichTextCodec.toHtml', () {
    test('inline formatting', () {
      final h = RichTextCodec.toHtml('**b** __i__ ++u++');
      expect(h, contains('<b>b</b>'));
      expect(h, contains('<i>i</i>'));
      expect(h, contains('<u>u</u>'));
    });
    test('escapes raw HTML (no injection)', () {
      final h = RichTextCodec.toHtml('<script>alert(1)</script>');
      expect(h, isNot(contains('<script>')));
      expect(h, contains('&lt;script&gt;'));
    });
    test('links only allow http(s)', () {
      expect(RichTextCodec.toHtml('[x](https://a.com)'), contains('<a href="https://a.com">x</a>'));
      expect(RichTextCodec.toHtml('[x](javascript:alert(1))'), isNot(contains('<a ')));
    });
    test('lists', () {
      final h = RichTextCodec.toHtml('• one\n• two\n1. a\n2. b');
      expect(h, contains('<ul><li>one</li><li>two</li></ul>'));
      expect(h, contains('<ol><li>a</li><li>b</li></ol>'));
    });
    test('plain text strips markers', () {
      expect(RichTextCodec.toPlain('**hi** [a](https://x.io)'), 'hi a (https://x.io)');
    });
  });

  group('HtmlUtils', () {
    test('toPlain removes scripts/styles and keeps structure', () {
      final t = HtmlUtils.toPlain('<style>x{}</style><p>Hello&nbsp;<b>World</b></p><ul><li>a</li></ul><a href="https://z.com">Z</a>');
      expect(t, contains('Hello World'));
      expect(t, contains('• a'));
      expect(t, contains('Z (https://z.com)'));
      expect(t, isNot(contains('x{}')));
    });
    test('snippet truncates', () {
      expect(HtmlUtils.snippet('<p>${'a' * 300}</p>', max: 50).length, 51);
    });
  });
}
