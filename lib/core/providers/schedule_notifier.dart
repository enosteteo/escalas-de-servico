import 'package:flutter/foundation.dart';
import '../../features/schedule/domain/models/generation_options.dart';
import '../../features/schedule/domain/models/schedule.dart';
import '../../features/schedule/domain/services/schedule_editor.dart';
import '../../features/schedule/domain/services/schedule_generator.dart';
import '../../features/service_type/domain/enums/service_type.dart';
import '../../features/volunteers/domain/models/volunteer.dart';

class ScheduleNotifier extends ChangeNotifier {
  final _generator = ScheduleGenerator();
  final _editor = ScheduleEditor();
  final List<Schedule> _schedules = [];

  List<Schedule> get schedules => List.unmodifiable(_schedules);

  bool hasExisting(int month, int year, ServiceType serviceType) {
    return _schedules.any(
      (s) => s.month == month && s.year == year && s.serviceType == serviceType,
    );
  }

  Schedule generate({
    required int month,
    required int year,
    required ServiceType serviceType,
    required List<Volunteer> volunteers,
    GenerationOptions options = const GenerationOptions(),
  }) {
    final s = _generator.generate(
      month: month,
      year: year,
      serviceType: serviceType,
      volunteers: volunteers,
      options: options,
    );
    _schedules.removeWhere(
      (x) => x.month == month && x.year == year && x.serviceType == serviceType,
    );
    _schedules.add(s);
    notifyListeners();
    return s;
  }

  void reassign({
    required String scheduleId,
    required DateTime entryDate,
    required String newVolunteerId,
    required List<Volunteer> availableVolunteers,
  }) {
    final idx = _schedules.indexWhere((s) => s.id == scheduleId);
    if (idx < 0) return;
    _schedules[idx] = _editor.reassign(
      schedule: _schedules[idx],
      entryDate: entryDate,
      newVolunteerId: newVolunteerId,
      availableVolunteers: availableVolunteers,
    );
    notifyListeners();
  }

  Schedule? findById(String id) {
    try {
      return _schedules.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
