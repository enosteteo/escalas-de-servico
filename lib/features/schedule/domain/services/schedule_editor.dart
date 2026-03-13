import '../../../volunteers/domain/models/volunteer.dart';
import '../models/schedule.dart';

class ScheduleEditor {
  Schedule reassign({
    required Schedule schedule,
    required DateTime entryDate,
    required String newVolunteerId,
    required List<Volunteer> availableVolunteers,
  }) {
    final idx = schedule.entries.indexWhere((e) => e.date == entryDate);
    if (idx < 0) throw ArgumentError('Data não encontrada na escala: $entryDate');

    final newVol = availableVolunteers.firstWhere(
      (v) => v.id == newVolunteerId,
      orElse: () => throw ArgumentError('Voluntário não encontrado: $newVolunteerId'),
    );

    if (!newVol.serviceTypes.contains(schedule.serviceType)) {
      throw ArgumentError(
        'O voluntário "${newVol.name}" não pertence ao tipo de culto desta escala.',
      );
    }

    final updated = [...schedule.entries];
    updated[idx] = updated[idx].copyWith(volunteerId: newVolunteerId);
    return schedule.copyWith(entries: updated);
  }

  Schedule swap({
    required Schedule schedule,
    required DateTime dateA,
    required DateTime dateB,
    required List<Volunteer> availableVolunteers,
  }) {
    final idxA = schedule.entries.indexWhere((e) => e.date == dateA);
    final idxB = schedule.entries.indexWhere((e) => e.date == dateB);
    if (idxA < 0) throw ArgumentError('Data A não encontrada: $dateA');
    if (idxB < 0) throw ArgumentError('Data B não encontrada: $dateB');

    final updated = [...schedule.entries];
    final idA = updated[idxA].volunteerId;
    final idB = updated[idxB].volunteerId;
    updated[idxA] = updated[idxA].copyWith(volunteerId: idB);
    updated[idxB] = updated[idxB].copyWith(volunteerId: idA);
    return schedule.copyWith(entries: updated);
  }
}
