import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_model.dart';
import 'language_service.dart';

final languageServiceProvider = Provider((ref) => LanguageService());

class LanguageNotifier extends Notifier<LanguageModel> {
  @override
  LanguageModel build() => LanguageModel.english; // main.dart me override hoga

  Future<void> change(BuildContext context, LanguageModel lang) async {
    await ref.read(languageServiceProvider).save(lang.code);
    await context.setLocale(lang.locale);   // bina restart ke UI badal jaata hai
    state = lang;
    // Optional: backend ko bhi batao (Step 8)
  }
}

final languageProvider =
NotifierProvider<LanguageNotifier, LanguageModel>(LanguageNotifier.new);