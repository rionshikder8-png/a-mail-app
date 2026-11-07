import 'package:a_mail/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('username', () {
    test('accepts valid', () {
      for (final u in ['rion', 'rion.shikder', 'a-b_c', 'user123']) {
        expect(Validators.username(u), isNull, reason: u);
      }
    });
    test('rejects invalid', () {
      expect(Validators.username(''), isNotNull);
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('-bad'), isNotNull);
      expect(Validators.username('bad.'), isNotNull);
      expect(Validators.username('has space'), isNotNull);
      expect(Validators.username('a..b'), isNotNull);
      expect(Validators.username('x' * 31), isNotNull);
    });
    test('is case-insensitive', () => expect(Validators.username('Rion'), isNull));
  });

  group('password', () {
    test('requires length, letters and digits', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('goodpass1'), isNull);
    });
    test('strength scales 0..4', () {
      expect(Validators.passwordStrength('abc'), 0);
      expect(Validators.passwordStrength('abcdefgh'), 1);
      expect(Validators.passwordStrength('Abcdefgh1!xy'), 4);
    });
  });

  group('email / otp', () {
    test('email', () {
      expect(Validators.isEmail('a@b.co'), isTrue);
      expect(Validators.isEmail('nope'), isFalse);
      expect(Validators.isEmail('a@b'), isFalse);
      expect(Validators.email('', optional: true), isNull);
      expect(Validators.email(''), isNotNull);
    });
    test('otp', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('1234'), isNotNull);
    });
  });
}
