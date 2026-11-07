import '../../models/email_model.dart';
import '../utils/validators.dart';

class AddressParser {
  AddressParser._();

  /// Parses `Name <a@b.c>, d@e.f` style input.
  static List<EmailAddress> parse(String input) {
    final out = <EmailAddress>[];
    for (final part in input.split(RegExp(r'[,;\n]'))) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final m = RegExp(r'^(.*?)<([^>]+)>$').firstMatch(p);
      if (m != null) {
        out.add(EmailAddress(name: m.group(1)!.trim().replaceAll('"', ''), address: m.group(2)!.trim()));
      } else {
        out.add(EmailAddress(address: p));
      }
    }
    return out;
  }

  static bool allValid(List<EmailAddress> l) => l.every((a) => Validators.isEmail(a.address));
}
