import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/volunteers/domain/services/volunteer_import_exporter.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

void main() {
  late VolunteerImportExporter exporter;

  setUp(() {
    exporter = VolunteerImportExporter();
  });

  group('exportToJson', () {
    test('exports empty list as empty JSON array', () {
      final result = exporter.exportToJson([]);
      expect(result, '[]');
    });

    test('exports single volunteer without age', () {
      final v = Volunteer(
        id: 'id-1',
        name: 'Ana',
        serviceTypes: [ServiceType.sundayOnly],
      );
      final json = exporter.exportToJson([v]);
      final parsed = exporter.importFromJson(json);

      expect(parsed.length, 1);
      expect(parsed.first.name, 'Ana');
      expect(parsed.first.serviceTypes, [ServiceType.sundayOnly]);
      expect(parsed.first.age, null);
      expect(parsed.first.canServeMultipleTimes, true);
      expect(parsed.first.minimumIntervalWeeks, 1);
    });

    test('exports volunteer with age and custom options', () {
      final v = Volunteer(
        id: 'id-2',
        name: 'Bianca',
        serviceTypes: [ServiceType.weekendService],
        age: 16,
        canServeMultipleTimes: false,
        minimumIntervalWeeks: 2,
      );
      final json = exporter.exportToJson([v]);
      final parsed = exporter.importFromJson(json);

      expect(parsed.first.age, 16);
      expect(parsed.first.canServeMultipleTimes, false);
      expect(parsed.first.minimumIntervalWeeks, 2);
    });

    test('exports volunteer with multiple service types', () {
      final v = Volunteer(
        id: 'id-3',
        name: 'Carlos',
        serviceTypes: [ServiceType.weekendService, ServiceType.sundayOnly],
      );
      final json = exporter.exportToJson([v]);
      final parsed = exporter.importFromJson(json);

      expect(parsed.first.serviceTypes,
          containsAll([ServiceType.weekendService, ServiceType.sundayOnly]));
    });

    test('exports multiple volunteers preserving order', () {
      final volunteers = [
        Volunteer(
            id: 'id-1', name: 'Ana', serviceTypes: [ServiceType.sundayOnly]),
        Volunteer(
            id: 'id-2', name: 'Bia', serviceTypes: [ServiceType.fridayOnly]),
      ];
      final json = exporter.exportToJson(volunteers);
      final parsed = exporter.importFromJson(json);

      expect(parsed.length, 2);
      expect(parsed[0].name, 'Ana');
      expect(parsed[1].name, 'Bia');
    });

    test('imported volunteers receive new IDs', () {
      final v = Volunteer(
          id: 'original-id',
          name: 'Ana',
          serviceTypes: [ServiceType.sundayOnly]);
      final json = exporter.exportToJson([v]);
      final parsed = exporter.importFromJson(json);

      expect(parsed.first.id, isNot('original-id'));
      expect(parsed.first.id, isNotEmpty);
    });
  });

  group('importFromJson', () {
    test('throws FormatException on invalid JSON', () {
      expect(
          () => exporter.importFromJson('not json'), throwsA(isA<FormatException>()));
    });

    test('throws FormatException on non-array JSON', () {
      expect(
          () => exporter.importFromJson('{}'), throwsA(isA<FormatException>()));
    });

    test('throws FormatException on unknown service type', () {
      const json =
          '[{"name":"Ana","serviceTypes":["unknownType"],"canServeMultipleTimes":true,"minimumIntervalWeeks":1}]';
      expect(
          () => exporter.importFromJson(json), throwsA(isA<FormatException>()));
    });

    test('imports volunteer with null age when age field absent', () {
      const json =
          '[{"name":"Raquel","serviceTypes":["weekendService"],"canServeMultipleTimes":true,"minimumIntervalWeeks":1}]';
      final result = exporter.importFromJson(json);
      expect(result.first.age, null);
    });

    test('imports all three service types correctly', () {
      const json =
          '[{"name":"X","serviceTypes":["weekendService","sundayOnly","fridayOnly"],"canServeMultipleTimes":true,"minimumIntervalWeeks":1}]';
      final result = exporter.importFromJson(json);
      expect(result.first.serviceTypes, [
        ServiceType.weekendService,
        ServiceType.sundayOnly,
        ServiceType.fridayOnly,
      ]);
    });

    test('roundtrip preserves all volunteer fields', () {
      final original = [
        Volunteer(
          id: 'id-1',
          name: 'Raquel',
          serviceTypes: [ServiceType.weekendService, ServiceType.sundayOnly],
          age: 25,
          canServeMultipleTimes: true,
          minimumIntervalWeeks: 3,
        ),
        Volunteer(
          id: 'id-2',
          name: 'Diego',
          serviceTypes: [ServiceType.fridayOnly],
          age: null,
          canServeMultipleTimes: false,
          minimumIntervalWeeks: 2,
        ),
      ];

      final json = exporter.exportToJson(original);
      final imported = exporter.importFromJson(json);

      expect(imported.length, 2);
      expect(imported[0].name, 'Raquel');
      expect(imported[0].age, 25);
      expect(imported[0].serviceTypes,
          containsAll([ServiceType.weekendService, ServiceType.sundayOnly]));
      expect(imported[0].minimumIntervalWeeks, 3);

      expect(imported[1].name, 'Diego');
      expect(imported[1].age, null);
      expect(imported[1].serviceTypes, [ServiceType.fridayOnly]);
      expect(imported[1].canServeMultipleTimes, false);
      expect(imported[1].minimumIntervalWeeks, 2);
    });
  });
}
