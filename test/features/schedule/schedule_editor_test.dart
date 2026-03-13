import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_editor.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_generator.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

void main() {
  late ScheduleGenerator generator;
  late ScheduleEditor editor;
  late List<Volunteer> volunteers;

  setUp(() {
    generator = ScheduleGenerator();
    editor = ScheduleEditor();
    volunteers = [
      Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.weekendService]),
      Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.weekendService]),
      Volunteer(id: '3', name: 'Carlos', serviceTypes: [ServiceType.weekendService]),
    ];
  });

  group('ScheduleEditor — reassign', () {
    test('reassigns entry to a different volunteer', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final entry = schedule.entries.first;
      final newId = volunteers.firstWhere((v) => v.id != entry.volunteerId).id;
      final updated = editor.reassign(schedule: schedule, entryDate: entry.date, newVolunteerId: newId, availableVolunteers: volunteers);
      expect(updated.entries.firstWhere((e) => e.date == entry.date).volunteerId, newId);
    });

    test('throws when volunteer does not belong to service type', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final wrong = Volunteer(id: '99', name: 'Estranho', serviceTypes: [ServiceType.fridayOnly]);
      expect(
        () => editor.reassign(
          schedule: schedule,
          entryDate: schedule.entries.first.date,
          newVolunteerId: wrong.id,
          availableVolunteers: [...volunteers, wrong],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when entry date not found', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(
        () => editor.reassign(schedule: schedule, entryDate: DateTime(2026, 3, 2), newVolunteerId: '1', availableVolunteers: volunteers),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('entry count unchanged after reassign', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      final entry = schedule.entries.first;
      final newId = volunteers.firstWhere((v) => v.id != entry.volunteerId).id;
      final updated = editor.reassign(schedule: schedule, entryDate: entry.date, newVolunteerId: newId, availableVolunteers: volunteers);
      expect(updated.entries.length, schedule.entries.length);
    });
  });

  group('ScheduleEditor — swap', () {
    test('swaps volunteers between two entries', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      late DateTime dateA, dateB;
      late String idA, idB;
      outer: for (int i = 0; i < schedule.entries.length; i++) {
        for (int j = i + 1; j < schedule.entries.length; j++) {
          if (schedule.entries[i].volunteerId != schedule.entries[j].volunteerId) {
            dateA = schedule.entries[i].date;
            dateB = schedule.entries[j].date;
            idA = schedule.entries[i].volunteerId;
            idB = schedule.entries[j].volunteerId;
            break outer;
          }
        }
      }
      final updated = editor.swap(schedule: schedule, dateA: dateA, dateB: dateB, availableVolunteers: volunteers);
      expect(updated.entries.firstWhere((e) => e.date == dateA).volunteerId, idB);
      expect(updated.entries.firstWhere((e) => e.date == dateB).volunteerId, idA);
    });

    test('throws when date not found', () {
      final schedule = generator.generate(month: 3, year: 2026, serviceType: ServiceType.weekendService, volunteers: volunteers);
      expect(
        () => editor.swap(schedule: schedule, dateA: DateTime(2026, 3, 2), dateB: schedule.entries.first.date, availableVolunteers: volunteers),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
