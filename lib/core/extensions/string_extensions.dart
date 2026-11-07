extension StringX on String {
  String get initial => trim().isEmpty ? '?' : trim()[0].toUpperCase();
  String capitalized() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
