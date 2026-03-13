import 'package:flutter_test/flutter_test.dart';
import 'package:igreja_em_escala/features/volunteers/domain/models/volunteer.dart';
import 'package:igreja_em_escala/features/volunteers/domain/repositories/volunteer_repository.dart';
import 'package:igreja_em_escala/features/service_type/domain/enums/service_type.dart';

class InMemoryVolunteerRepository implements VolunteerRepository {
  final List<Volunteer> _volunteers = [];

  @override
  Future<List<Volunteer>> getAll() async => List.unmodifiable(_volunteers);

  @override
  Future<void> save(Volunteer volunteer) async {
    final index = _volunteers.indexWhere((v) => v.id == volunteer.id);
    if (index >= 0) {
      _volunteers[index] = volunteer;
    } else {
      _volunteers.add(volunteer);
    }
  }

  @override
  Future<void> delete(String id) async {
    _volunteers.removeWhere((v) => v.id == id);
  }

  @override
  Future<bool> existsByName(String name) async {
    return _volunteers.any((v) => v.name.toLowerCase() == name.toLowerCase());
  }
}

void main() {
  group('VolunteerRepository', () {
    late InMemoryVolunteerRepository repo;
    setUp(() { repo = InMemoryVolunteerRepository(); });

    test('starts empty', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('saves a volunteer and retrieves it', () async {
      final v = Volunteer(id: '1', name: 'Maria', serviceTypes: [ServiceType.weekendService]);
      await repo.save(v);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Maria');
    });

    test('updates existing volunteer', () async {
      final v = Volunteer(id: '1', name: 'Maria', serviceTypes: [ServiceType.weekendService]);
      await repo.save(v);
      final updated = Volunteer(id: '1', name: 'Maria Atualizada', serviceTypes: [ServiceType.sundayOnly]);
      await repo.save(updated);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Maria Atualizada');
    });

    test('deletes a volunteer by id', () async {
      await repo.save(Volunteer(id: '1', name: 'Pedro', serviceTypes: [ServiceType.weekendService]));
      await repo.delete('1');
      expect(await repo.getAll(), isEmpty);
    });

    test('existsByName returns true case-insensitively', () async {
      await repo.save(Volunteer(id: '1', name: 'João', serviceTypes: [ServiceType.weekendService]));
      expect(await repo.existsByName('joão'), isTrue);
      expect(await repo.existsByName('JOÃO'), isTrue);
    });

    test('existsByName returns false for non-existing', () async {
      expect(await repo.existsByName('Alguém'), isFalse);
    });
  });
}
