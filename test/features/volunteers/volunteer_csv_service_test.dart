import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/volunteers/domain/services/volunteer_csv_service.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

void main() {
  late VolunteerCsvService service;

  setUp(() {
    service = VolunteerCsvService();
  });

  group('VolunteerCsvService — export', () {
    test('produces header row', () {
      final csv = service.export([]);
      expect(csv.trim().split('\n').first, contains('Nome'));
    });

    test('exports volunteer with all fields', () {
      final v = Volunteer(
        id: '1', name: 'Ana', age: 15,
        serviceTypes: [ServiceType.weekendService],
        canServeMultipleTimes: true, minimumIntervalWeeks: 1,
      );
      final csv = service.export([v]);
      expect(csv, contains('Ana'));
      expect(csv, contains('15'));
      expect(csv, contains('weekendService'));
      expect(csv, contains('true'));
      expect(csv, contains('1'));
    });

    test('exports volunteer with null age as empty string', () {
      final v = Volunteer(
        id: '1', name: 'Bia', age: null,
        serviceTypes: [ServiceType.sundayOnly],
        canServeMultipleTimes: false, minimumIntervalWeeks: 2,
      );
      final csv = service.export([v]);
      final dataRow = csv.trim().split('\n')[1];
      final cols = dataRow.split(',');
      expect(cols[1], isEmpty); // age column empty
    });

    test('exports multiple service types', () {
      final v = Volunteer(
        id: '1', name: 'Carlos', age: null,
        serviceTypes: [ServiceType.weekendService, ServiceType.fridayOnly],
        canServeMultipleTimes: true, minimumIntervalWeeks: 1,
      );
      final csv = service.export([v]);
      expect(csv, contains('weekendService'));
      expect(csv, contains('fridayOnly'));
    });

    test('exports multiple volunteers', () {
      final volunteers = [
        Volunteer(id: '1', name: 'Ana', serviceTypes: [ServiceType.weekendService], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', serviceTypes: [ServiceType.sundayOnly], canServeMultipleTimes: false, minimumIntervalWeeks: 2),
      ];
      final csv = service.export(volunteers);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // header + 2 data rows
    });
  });

  group('VolunteerCsvService — import', () {
    test('parses volunteer with all fields', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'Ana,15,weekendService,true,1\n';
      final result = service.import(csv);
      expect(result.length, 1);
      expect(result.first.name, 'Ana');
      expect(result.first.age, 15);
      expect(result.first.serviceTypes, contains(ServiceType.weekendService));
      expect(result.first.canServeMultipleTimes, isTrue);
      expect(result.first.minimumIntervalWeeks, 1);
    });

    test('parses volunteer with empty age as null', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'Bia,,sundayOnly,false,2\n';
      final result = service.import(csv);
      expect(result.first.age, isNull);
    });

    test('parses multiple service types', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'Carlos,,weekendService|fridayOnly,true,1\n';
      final result = service.import(csv);
      expect(result.first.serviceTypes, containsAll([ServiceType.weekendService, ServiceType.fridayOnly]));
    });

    test('skips rows with wrong column count', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'valid,,sundayOnly,true,1\n'
          'bad,only,two cols\n';
      final result = service.import(csv);
      expect(result.length, 1);
    });

    test('skips rows with invalid service type names', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'Bad,,invalidType,true,1\n'
          'Good,,sundayOnly,true,1\n';
      final result = service.import(csv);
      expect(result.length, 1);
      expect(result.first.name, 'Good');
    });

    test('generates new UUIDs (not empty) for imported volunteers', () {
      const csv = 'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas\n'
          'Ana,,weekendService,true,1\n';
      final result = service.import(csv);
      expect(result.first.id, isNotEmpty);
    });

    test('import then export round-trips correctly', () {
      final original = [
        Volunteer(id: '1', name: 'Ana', age: 20, serviceTypes: [ServiceType.weekendService, ServiceType.sundayOnly], canServeMultipleTimes: true, minimumIntervalWeeks: 1),
        Volunteer(id: '2', name: 'Bia', age: null, serviceTypes: [ServiceType.fridayOnly], canServeMultipleTimes: false, minimumIntervalWeeks: 3),
      ];
      final csv = service.export(original);
      final reimported = service.import(csv);
      expect(reimported.length, original.length);
      expect(reimported[0].name, original[0].name);
      expect(reimported[0].age, original[0].age);
      expect(reimported[0].canServeMultipleTimes, original[0].canServeMultipleTimes);
      expect(reimported[1].minimumIntervalWeeks, original[1].minimumIntervalWeeks);
    });
  });
}
