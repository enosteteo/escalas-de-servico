class SettingsValidator {
  String? validateChurchName(String name) {
    if (name.trim().isEmpty) return 'O nome da igreja não pode ser vazio.';
    return null;
  }
}
