import '../../../service_type/domain/enums/service_type.dart';

class Volunteer {
  final String id;
  final String name;
  final List<ServiceType> serviceTypes;
  final int? age;
  final bool canServeMultipleTimes;
  final int minimumIntervalWeeks;

  const Volunteer({
    required this.id,
    required this.name,
    required this.serviceTypes,
    this.age,
    this.canServeMultipleTimes = true,
    this.minimumIntervalWeeks = 1,
  });

  Volunteer copyWith({
    String? id,
    String? name,
    List<ServiceType>? serviceTypes,
    Object? age = _sentinel,
    bool? canServeMultipleTimes,
    int? minimumIntervalWeeks,
  }) {
    return Volunteer(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      age: age == _sentinel ? this.age : age as int?,
      canServeMultipleTimes:
          canServeMultipleTimes ?? this.canServeMultipleTimes,
      minimumIntervalWeeks: minimumIntervalWeeks ?? this.minimumIntervalWeeks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Volunteer && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Sentinel value to distinguish null from "not provided" in copyWith
const _sentinel = Object();
