import 'package:shared_preferences/shared_preferences.dart';
import 'language_model.dart';

class LanguageService {
  static const _key = 'app_language';

  Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  Future<LanguageModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LanguageModel.fromCode(prefs.getString(_key));
  }
}