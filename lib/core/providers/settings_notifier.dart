import 'package:flutter/foundation.dart';
import '../../features/settings/domain/models/settings.dart';

class SettingsNotifier extends ChangeNotifier {
  Settings _settings = const Settings(churchName: '');

  Settings get settings => _settings;

  void setChurchName(String name) {
    _settings = _settings.copyWith(churchName: name.trim());
    notifyListeners();
  }

  void toggleDarkMode() {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    notifyListeners();
  }
}
