import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';
import 'package:igreja_em_escala/features/service_type/domain/extensions/service_type_extension.dart';

void main() {
  group('ServiceType weekdays', () {
    test('weekendService has Saturday (6) and Sunday (7)', () {
      expect(ServiceType.weekendService.weekdays, containsAll([6, 7]));
      expect(ServiceType.weekendService.weekdays.length, 2);
    });
    test('sundayOnly has only Sunday (7)', () {
      expect(ServiceType.sundayOnly.weekdays, equals([7]));
    });
    test('fridayOnly has only Friday (5)', () {
      expect(ServiceType.fridayOnly.weekdays, equals([5]));
    });
    test('weekendService label is "Fim de Semana"', () {
      expect(ServiceType.weekendService.label, 'Fim de Semana');
    });
    test('sundayOnly label is "Apenas Domingo"', () {
      expect(ServiceType.sundayOnly.label, 'Apenas Domingo');
    });
    test('fridayOnly label is "Apenas Sexta"', () {
      expect(ServiceType.fridayOnly.label, 'Apenas Sexta');
    });
    test('weekday lists are immutable', () {
      expect(() => ServiceType.weekendService.weekdays.add(1), throwsUnsupportedError);
    });
  });
}
