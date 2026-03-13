import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../features/volunteers/domain/models/volunteer.dart';
import '../../features/service_type/domain/enums/service_type.dart';

class VolunteerNotifier extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<Volunteer> _volunteers = [];

  List<Volunteer> get volunteers => List.unmodifiable(_volunteers);

  void add(
    String name,
    List<ServiceType> serviceTypes, {
    int? age,
    bool canServeMultipleTimes = true,
    int minimumIntervalWeeks = 1,
  }) {
    if (_volunteers.any(
        (v) => v.name.toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('Já existe um voluntário com esse nome.');
    }
    _volunteers.add(Volunteer(
      id: _uuid.v4(),
      name: name.trim(),
      serviceTypes: serviceTypes,
      age: age,
      canServeMultipleTimes: canServeMultipleTimes,
      minimumIntervalWeeks: minimumIntervalWeeks,
    ));
    notifyListeners();
  }

  void update(
    String id,
    String name,
    List<ServiceType> serviceTypes, {
    int? age,
    bool canServeMultipleTimes = true,
    int minimumIntervalWeeks = 1,
  }) {
    if (_volunteers.any(
      (v) => v.id != id && v.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      throw ArgumentError('Já existe um voluntário com esse nome.');
    }
    final idx = _volunteers.indexWhere((v) => v.id == id);
    if (idx < 0) return;
    _volunteers[idx] = _volunteers[idx].copyWith(
      name: name.trim(),
      serviceTypes: serviceTypes,
      age: age,
      canServeMultipleTimes: canServeMultipleTimes,
      minimumIntervalWeeks: minimumIntervalWeeks,
    );
    notifyListeners();
  }

  void remove(String id) {
    _volunteers.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}
