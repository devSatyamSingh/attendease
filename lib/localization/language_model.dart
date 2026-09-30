import 'dart:ui';

class LanguageModel {
  final String code;
  final String name;        // Native name, jo selection screen me dikhega
  final bool isRtl;

  const LanguageModel({required this.code, required this.name, this.isRtl = false});

  Locale get locale => Locale(code);

  static const english = LanguageModel(code: 'en', name: 'English');
  static const hindi   = LanguageModel(code: 'hi', name: 'हिन्दी');
  static const urdu    = LanguageModel(code: 'ur', name: 'اردو', isRtl: true);

  static const all = [english, hindi, urdu];

  static LanguageModel fromCode(String? code) =>
      all.firstWhere((l) => l.code == code, orElse: () => english);
}