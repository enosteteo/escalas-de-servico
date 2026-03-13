import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/settings/domain/validators/settings_validator.dart';

void main() {
  group('SettingsValidator', () {
    late SettingsValidator validator;
    setUp(() { validator = SettingsValidator(); });

    test('returns error for empty church name', () {
      expect(validator.validateChurchName(''), isNotNull);
    });
    test('returns error for whitespace-only church name', () {
      expect(validator.validateChurchName('   '), isNotNull);
    });
    test('returns null for valid church name', () {
      expect(validator.validateChurchName('Igreja Central'), isNull);
    });
  });
}
