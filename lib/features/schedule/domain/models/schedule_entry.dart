class ScheduleEntry {
  final DateTime date;
  final String volunteerId;

  const ScheduleEntry({required this.date, required this.volunteerId});

  ScheduleEntry copyWith({DateTime? date, String? volunteerId}) {
    return ScheduleEntry(
      date: date ?? this.date,
      volunteerId: volunteerId ?? this.volunteerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleEntry && date == other.date && volunteerId == other.volunteerId;

  @override
  int get hashCode => Object.hash(date, volunteerId);
}
