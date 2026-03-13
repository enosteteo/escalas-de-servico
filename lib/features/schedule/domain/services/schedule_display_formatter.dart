class ScheduleDisplayFormatter {
  /// Joins a list of names with commas and the Portuguese additive "e" before the last.
  ///
  /// Examples:
  ///   [] → ''
  ///   ['Ana'] → 'Ana'
  ///   ['Ana', 'Bia'] → 'Ana e Bia'
  ///   ['Ana', 'Bia', 'Carlos'] → 'Ana, Bia e Carlos'
  String joinNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} e ${names[1]}';
    return '${names.take(names.length - 1).join(', ')} e ${names.last}';
  }
}
