import '../../../service_type/domain/extensions/service_type_extension.dart';
import 'schedule_display_formatter.dart';
import '../models/schedule.dart';

class ExportRow {
  final DateTime date;
  final String volunteerName;
  const ExportRow({required this.date, required this.volunteerName});
}

class ExportData {
  final String churchName;
  final int month;
  final int year;
  final String serviceTypeLabel;
  final List<ExportRow> rows;

  const ExportData({
    required this.churchName,
    required this.month,
    required this.year,
    required this.serviceTypeLabel,
    required this.rows,
  });
}

class ScheduleExporter {
  void validateExport({required String churchName, required Schedule schedule}) {
    if (churchName.trim().isEmpty) {
      throw ArgumentError('O nome da igreja não pode ser vazio.');
    }
    if (schedule.entries.isEmpty) {
      throw ArgumentError('A escala não possui entradas para exportar.');
    }
  }

  ExportData buildExportData({
    required String churchName,
    required Schedule schedule,
    required Map<String, String> volunteerMap,
  }) {
    final formatter = ScheduleDisplayFormatter();
    final sorted = [...schedule.entries]..sort((a, b) => a.date.compareTo(b.date));

    // Group entries by date, preserving sorted order.
    final grouped = <DateTime, List<String>>{};
    for (final e in sorted) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      grouped.putIfAbsent(key, () => []).add(volunteerMap[e.volunteerId] ?? 'Desconhecido');
    }

    final rows = grouped.entries
        .map((e) => ExportRow(
              date: e.key,
              volunteerName: formatter.joinNames(e.value),
            ))
        .toList();

    return ExportData(
      churchName: churchName,
      month: schedule.month,
      year: schedule.year,
      serviceTypeLabel: schedule.serviceType.label,
      rows: rows,
    );
  }
}
