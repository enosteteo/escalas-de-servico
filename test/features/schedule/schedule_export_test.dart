import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/schedule/domain/models/generation_options.dart';
import 'package:igreja_em_escala/features/schedule/domain/models/schedule.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_exporter.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_generator.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';
import 'package:igreja_em_escala/features/service_type/domain/extensions/service_type_extension.dart';

void main() {
  late ScheduleExporter exporter;
  late ScheduleGenerator generator;
  late List<Volunteer> volunteers;

  setUp(() {
    exporter = ScheduleExporter();
    generator = ScheduleGenerator();
    volunteers = [
      Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.weekendService]),
      Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.weekendService]),
    ];
  });

  group('validation', () {
    test('throws for empty church name', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(() => exporter.validateExport(churchName: '', schedule: s), throwsA(isA<ArgumentError>()));
    });
    test('throws for whitespace church name', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(() => exporter.validateExport(churchName: '   ', schedule: s), throwsA(isA<ArgumentError>()));
    });
    test('does not throw for valid inputs', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(() => exporter.validateExport(churchName: 'Igreja Teste', schedule: s), returnsNormally);
    });
    test('throws when schedule has no entries', () {
      final empty = Schedule(id: 'x', month: 3, year: 2026, serviceType: ServiceType.weekendService, entries: []);
      expect(() => exporter.validateExport(churchName: 'Igreja', schedule: empty), throwsA(isA<ArgumentError>()));
    });
  });

  group('buildExportData', () {
    test('returns correct metadata', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final data = exporter.buildExportData(
        churchName: 'Igreja Graça',
        schedule: s,
        volunteerMap: {for (final v in volunteers) v.id: v.name},
      );
      expect(data.churchName, 'Igreja Graça');
      expect(data.month, 3);
      expect(data.year, 2026);
      expect(data.serviceTypeLabel, ServiceType.weekendService.label);
    });
    test('rows sorted by date', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final data = exporter.buildExportData(
        churchName: 'Igreja',
        schedule: s,
        volunteerMap: {for (final v in volunteers) v.id: v.name},
      );
      for (int i = 0; i < data.rows.length - 1; i++) {
        expect(data.rows[i].date.isBefore(data.rows[i + 1].date), isTrue);
      }
    });
    test('rows contain volunteer names not ids', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final vMap = {for (final v in volunteers) v.id: v.name};
      final data = exporter.buildExportData(churchName: 'Igreja', schedule: s, volunteerMap: vMap);
      for (final row in data.rows) {
        expect(row.volunteerName, isNotEmpty);
      }
    });
    test('one row per unique date (not per entry)', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final data = exporter.buildExportData(
        churchName: 'Igreja',
        schedule: s,
        volunteerMap: {for (final v in volunteers) v.id: v.name},
      );
      final uniqueDates = s.entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
      expect(data.rows.length, uniqueDates.length);
    });
    test('same-day entries are joined with commas and "e"', () {
      // Generate 2 volunteers per day so same-day grouping is exercised.
      final twoPerDay = [
        Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly]),
        Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly]),
      ];
      final s = generator.generate(
        month: 3,
        year: 2026,
        serviceType: ServiceType.sundayOnly,
        volunteers: twoPerDay,
        options: const GenerationOptions(volunteersPerDay: 2),
      );
      final data = exporter.buildExportData(
        churchName: 'Igreja',
        schedule: s,
        volunteerMap: {for (final v in twoPerDay) v.id: v.name},
      );
      // Every row should have both names joined.
      for (final row in data.rows) {
        expect(row.volunteerName, contains('e'));
      }
    });
    test('single-volunteer days show only that name', () {
      final oneVol = [
        Volunteer(id: '1', name: 'Carlos', serviceTypes: [ServiceType.sundayOnly]),
      ];
      final s = generator.generate(
        month: 3, year: 2026,
        serviceType: ServiceType.sundayOnly,
        volunteers: oneVol,
      );
      final data = exporter.buildExportData(
        churchName: 'Igreja',
        schedule: s,
        volunteerMap: {'1': 'Carlos'},
      );
      for (final row in data.rows) {
        expect(row.volunteerName, 'Carlos');
      }
    });
  });
}
