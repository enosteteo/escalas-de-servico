import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/schedule/domain/models/generation_options.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_generator.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

void main() {
  late ScheduleGenerator generator;
  setUp(() { generator = ScheduleGenerator(); });

  group('ScheduleGenerator — weekendService', () {
    // March 2026: Sat 7,14,21,28 + Sun 1,8,15,22,29 = 9 entries
    final volunteers = [
      Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.weekendService], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.weekendService], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '3', name: 'Carlos', serviceTypes: [ServiceType.weekendService], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
    ];

    test('generates entries only for Saturdays and Sundays', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      for (final e in s.entries) {
        expect(e.date.weekday == 6 || e.date.weekday == 7, isTrue);
      }
    });

    test('generates 9 entries for March 2026', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(s.entries.length, 9);
    });

    test('entries are sorted by date', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      for (int i = 0; i < s.entries.length - 1; i++) {
        expect(s.entries[i].date.isBefore(s.entries[i + 1].date), isTrue);
      }
    });

    test('volunteers distributed evenly (max diff 1)', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final counts = <String, int>{};
      for (final e in s.entries) {
        counts[e.volunteerId] = (counts[e.volunteerId] ?? 0) + 1;
      }
      final vals = counts.values.toList();
      expect(vals.reduce((a, b) => a > b ? a : b) - vals.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(1));
    });

    test('all volunteers assigned at least once', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final ids = s.entries.map((e) => e.volunteerId).toSet();
      for (final v in volunteers) { expect(ids, contains(v.id)); }
    });

    test('is deterministic', () {
      final s1 = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final s2 = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      for (int i = 0; i < s1.entries.length; i++) {
        expect(s1.entries[i].volunteerId, s2.entries[i].volunteerId);
        expect(s1.entries[i].date, s2.entries[i].date);
      }
    });

    test('throws ArgumentError when no volunteers', () {
      expect(
        () => generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('schedule has correct month, year, serviceType', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(s.month, 3);
      expect(s.year, 2026);
      expect(s.serviceType, ServiceType.weekendService);
    });
  });

  group('ScheduleGenerator — sundayOnly', () {
    // March 2026: Sun 1,8,15,22,29 = 5 entries
    final volunteers = [
      Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
    ];

    test('generates entries only for Sundays', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers);
      for (final e in s.entries) { expect(e.date.weekday, 7); }
    });

    test('generates 5 entries for March 2026', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers);
      expect(s.entries.length, 5);
    });

    test('distribution: 3 and 2 for 5 entries 2 volunteers', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers);
      final counts = <String, int>{};
      for (final e in s.entries) { counts[e.volunteerId] = (counts[e.volunteerId] ?? 0) + 1; }
      final vals = counts.values.toList()..sort();
      expect(vals, equals([2, 3]));
    });
  });

  group('ScheduleGenerator — fridayOnly', () {
    // March 2026: Fri 6,13,20,27 = 4 entries
    final volunteers = [
      Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.fridayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.fridayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '3', name: 'Carlos', serviceTypes: [ServiceType.fridayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      Volunteer(id: '4', name: 'Diego', serviceTypes: [ServiceType.fridayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
    ];

    test('generates entries only for Fridays', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.fridayOnly, volunteers: volunteers);
      for (final e in s.entries) { expect(e.date.weekday, 5); }
    });

    test('generates 4 entries for March 2026', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.fridayOnly, volunteers: volunteers);
      expect(s.entries.length, 4);
    });

    test('each volunteer gets exactly 1 entry', () {
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.fridayOnly, volunteers: volunteers);
      final counts = <String, int>{};
      for (final e in s.entries) { counts[e.volunteerId] = (counts[e.volunteerId] ?? 0) + 1; }
      expect(counts.values.every((c) => c == 1), isTrue);
    });
  });

  group('ScheduleGenerator — with options', () {
    test('requireAgeGroupPairing creates 2 entries per day', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', age: 15, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', age: 25, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers, options: const GenerationOptions(requireAgeGroupPairing: true));
      expect(s.entries.length, 10); // 5 Sundays * 2 volunteers each
    });

    test('requireAgeGroupPairing throws when no minors', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', age: 25, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', age: 30, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      expect(() => generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers, options: const GenerationOptions(requireAgeGroupPairing: true)), throwsA(isA<ArgumentError>()));
    });

    test('requireAgeGroupPairing throws when no adults', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', age: 15, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', age: 16, serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      expect(() => generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers, options: const GenerationOptions(requireAgeGroupPairing: true)), throwsA(isA<ArgumentError>()));
    });

    test('volunteersPerDay=2 creates 2 entries per day', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '3', name: 'Carlos', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers, options: const GenerationOptions(volunteersPerDay: 2));
      expect(s.entries.length, 10); // 5 Sundays * 2
    });

    test('canServeMultipleTimes=false limits volunteer to once per month', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: false, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers);
      final anaCount = s.entries.where((e) => e.volunteerId == '1').length;
      expect(anaCount, lessThanOrEqualTo(1));
    });

    test('minimumIntervalWeeks=2 enforces gap between assignments', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 2),
        Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
      ];
      final s = generator.generate(month: 3, year: 2026, serviceType: ServiceType.sundayOnly, volunteers: volunteers);
      final anaDates = s.entries.where((e) => e.volunteerId == '1').map((e) => e.date).toList()..sort();
      for (int i = 0; i < anaDates.length - 1; i++) {
        final diff = anaDates[i + 1].difference(anaDates[i]).inDays;
        expect(diff, greaterThanOrEqualTo(14));
      }
    });
  });
}
