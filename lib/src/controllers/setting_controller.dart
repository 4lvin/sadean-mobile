import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxBool darkMode = false.obs;
  final RxString language = 'id'.obs;

  void toggleDarkMode() {
    darkMode.value = !darkMode.value;
    // In a real app, you would save this preference
  }

  void setLanguage(String lang) {
    language.value = lang;
    // In a real app, you would apply the language change
  }
}
