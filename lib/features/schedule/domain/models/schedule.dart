import '../../../service_type/domain/enums/service_type.dart';
import 'schedule_entry.dart';

class Schedule {
  final String id;
  final int month;
  final int year;
  final ServiceType serviceType;
  final List<ScheduleEntry> entries;

  const Schedule({
    required this.id,
    required this.month,
    required this.year,
    required this.serviceType,
    required this.entries,
  });

  Schedule copyWith({
    String? id,
    int? month,
    int? year,
    ServiceType? serviceType,
    List<ScheduleEntry>? entries,
  }) {
    return Schedule(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      serviceType: serviceType ?? this.serviceType,
      entries: entries ?? this.entries,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Schedule && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
