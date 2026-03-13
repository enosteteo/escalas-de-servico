import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/schedule/domain/services/schedule_display_formatter.dart';

void main() {
  late ScheduleDisplayFormatter formatter;
  setUp(() { formatter = ScheduleDisplayFormatter(); });

  group('ScheduleDisplayFormatter — joinNames', () {
    test('empty list returns empty string', () {
      expect(formatter.joinNames([]), '');
    });

    test('single name returns just the name', () {
      expect(formatter.joinNames(['Ana']), 'Ana');
    });

    test('two names joined with "e"', () {
      expect(formatter.joinNames(['Ana', 'Bia']), 'Ana e Bia');
    });

    test('three names: comma between first two, "e" before last', () {
      expect(formatter.joinNames(['Ana', 'Bia', 'Carlos']), 'Ana, Bia e Carlos');
    });

    test('four names: commas between first three, "e" before last', () {
      expect(formatter.joinNames(['Ana', 'Bia', 'Carlos', 'Diego']), 'Ana, Bia, Carlos e Diego');
    });
  });
}
