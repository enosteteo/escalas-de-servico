import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/volunteers/domain/validators/volunteer_validator.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

void main() {
  group('VolunteerValidator', () {
    late VolunteerValidator validator;
    setUp(() { validator = VolunteerValidator(); });

    group('validateName', () {
      test('returns error for empty name', () {
        expect(validator.validateName(''), isNotNull);
      });
      test('returns error for whitespace-only name', () {
        expect(validator.validateName('   '), isNotNull);
      });
      test('returns null for valid name', () {
        expect(validator.validateName('João Silva'), isNull);
      });
    });

    group('validateServiceTypes', () {
      test('returns error when no service types assigned', () {
        expect(validator.validateServiceTypes([]), isNotNull);
      });
      test('returns null when at least one service type assigned', () {
        expect(validator.validateServiceTypes([ServiceType.weekendService]), isNull);
      });
      test('returns null when multiple service types assigned', () {
        expect(validator.validateServiceTypes([ServiceType.weekendService, ServiceType.sundayOnly]), isNull);
      });
    });
  });
}
