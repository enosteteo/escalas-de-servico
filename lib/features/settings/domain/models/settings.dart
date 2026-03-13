class Settings {
  final String churchName;
  final bool isDarkMode;

  const Settings({required this.churchName, this.isDarkMode = false});

  Settings copyWith({String? churchName, bool? isDarkMode}) {
    return Settings(
      churchName: churchName ?? this.churchName,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
