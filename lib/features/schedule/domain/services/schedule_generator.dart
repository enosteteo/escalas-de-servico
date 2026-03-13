import 'package:uuid/uuid.dart';
import '../../../service_type/domain/enums/service_type.dart';
import '../../../service_type/domain/extensions/service_type_extension.dart';
import '../../../volunteers/domain/models/volunteer.dart';
import '../models/generation_options.dart';
import '../models/schedule.dart';
import '../models/schedule_entry.dart';

class ScheduleGenerator {
  final Uuid _uuid;

  ScheduleGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Schedule generate({
    required int month,
    required int year,
    required ServiceType serviceType,
    required List<Volunteer> volunteers,
    GenerationOptions options = const GenerationOptions(),
  }) {
    if (volunteers.isEmpty) {
      throw ArgumentError('Não há voluntários para gerar a escala.');
    }

    final days = _eligibleDays(month, year, serviceType);
    final sorted = [...volunteers]..sort((a, b) => a.name.compareTo(b.name));

    List<ScheduleEntry> entries;
    if (options.requireAgeGroupPairing) {
      entries = _generateWithPairing(days, sorted);
    } else if (options.volunteersPerDay > 1) {
      entries = _generateMultiPerDay(days, sorted, options.volunteersPerDay);
    } else {
      entries = _generateDefault(days, sorted);
    }

    return Schedule(
      id: _uuid.v4(),
      month: month,
      year: year,
      serviceType: serviceType,
      entries: entries,
    );
  }

  /// Original round-robin, single volunteer per day, with new constraints.
  List<ScheduleEntry> _generateDefault(
      List<DateTime> days, List<Volunteer> sorted) {
    final entries = <ScheduleEntry>[];
    // Track assigned dates per volunteer id
    final assignedDates = <String, List<DateTime>>{};
    // Track volunteers who can no longer serve (canServeMultipleTimes=false already assigned)
    final exhausted = <String>{};

    int idx = 0;
    for (final day in days) {
      // Try to find next eligible volunteer
      Volunteer? chosen;
      for (int attempt = 0; attempt < sorted.length; attempt++) {
        final candidate = sorted[(idx + attempt) % sorted.length];
        if (_isEligible(candidate, day, assignedDates, exhausted)) {
          chosen = candidate;
          idx = (idx + attempt + 1) % sorted.length;
          break;
        }
      }
      // Fallback: ignore constraints, pick next round-robin
      if (chosen == null) {
        chosen = sorted[idx % sorted.length];
        idx = (idx + 1) % sorted.length;
      }
      entries.add(ScheduleEntry(date: day, volunteerId: chosen.id));
      _recordAssignment(chosen, day, assignedDates, exhausted);
    }
    return entries;
  }

  /// N volunteers per day (no pairing), round-robin respecting constraints.
  List<ScheduleEntry> _generateMultiPerDay(
      List<DateTime> days, List<Volunteer> sorted, int n) {
    final entries = <ScheduleEntry>[];
    final assignedDates = <String, List<DateTime>>{};
    final exhausted = <String>{};

    int idx = 0;
    for (final day in days) {
      final assignedToday = <String>{};
      int assigned = 0;
      int fallbackIdx = idx;

      // First pass: try to find N volunteers respecting constraints
      for (int attempt = 0;
          attempt < sorted.length && assigned < n;
          attempt++) {
        final candidate = sorted[(idx + attempt) % sorted.length];
        if (assignedToday.contains(candidate.id)) continue;
        if (_isEligible(candidate, day, assignedDates, exhausted)) {
          entries.add(ScheduleEntry(date: day, volunteerId: candidate.id));
          _recordAssignment(candidate, day, assignedDates, exhausted);
          assignedToday.add(candidate.id);
          assigned++;
          if (assigned == 1) idx = (idx + attempt + 1) % sorted.length;
        }
      }

      // Fallback: fill remaining slots ignoring constraints
      if (assigned < n) {
        for (int attempt = 0;
            attempt < sorted.length && assigned < n;
            attempt++) {
          final candidate = sorted[(fallbackIdx + attempt) % sorted.length];
          if (assignedToday.contains(candidate.id)) continue;
          entries.add(ScheduleEntry(date: day, volunteerId: candidate.id));
          _recordAssignment(candidate, day, assignedDates, exhausted);
          assignedToday.add(candidate.id);
          assigned++;
        }
      }
    }
    return entries;
  }

  /// Age-group pairing: 1 minor (age < 18) + 1 adult (age >= 18 or null) per day.
  List<ScheduleEntry> _generateWithPairing(
      List<DateTime> days, List<Volunteer> sorted) {
    final minors = sorted
        .where((v) => v.age != null && v.age! < 18)
        .toList();
    final adults = sorted
        .where((v) => v.age == null || v.age! >= 18)
        .toList();

    if (minors.isEmpty) {
      throw ArgumentError(
          'Não há menores de idade para emparelhar. Adicione voluntários com menos de 18 anos.');
    }
    if (adults.isEmpty) {
      throw ArgumentError(
          'Não há adultos para emparelhar. Adicione voluntários com 18 anos ou mais.');
    }

    final entries = <ScheduleEntry>[];
    final assignedDatesMinors = <String, List<DateTime>>{};
    final assignedDatesAdults = <String, List<DateTime>>{};
    final exhaustedMinors = <String>{};
    final exhaustedAdults = <String>{};

    int minorIdx = 0;
    int adultIdx = 0;

    for (final day in days) {
      // Assign 1 minor
      Volunteer? minor;
      for (int attempt = 0; attempt < minors.length; attempt++) {
        final candidate = minors[(minorIdx + attempt) % minors.length];
        if (_isEligible(
            candidate, day, assignedDatesMinors, exhaustedMinors)) {
          minor = candidate;
          minorIdx = (minorIdx + attempt + 1) % minors.length;
          break;
        }
      }
      // Fallback minor
      if (minor == null) {
        minor = minors[minorIdx % minors.length];
        minorIdx = (minorIdx + 1) % minors.length;
      }

      // Assign 1 adult
      Volunteer? adult;
      for (int attempt = 0; attempt < adults.length; attempt++) {
        final candidate = adults[(adultIdx + attempt) % adults.length];
        if (_isEligible(
            candidate, day, assignedDatesAdults, exhaustedAdults)) {
          adult = candidate;
          adultIdx = (adultIdx + attempt + 1) % adults.length;
          break;
        }
      }
      // Fallback adult
      if (adult == null) {
        adult = adults[adultIdx % adults.length];
        adultIdx = (adultIdx + 1) % adults.length;
      }

      entries.add(ScheduleEntry(date: day, volunteerId: minor.id));
      entries.add(ScheduleEntry(date: day, volunteerId: adult.id));
      _recordAssignment(minor, day, assignedDatesMinors, exhaustedMinors);
      _recordAssignment(adult, day, assignedDatesAdults, exhaustedAdults);
    }
    return entries;
  }

  bool _isEligible(
    Volunteer volunteer,
    DateTime day,
    Map<String, List<DateTime>> assignedDates,
    Set<String> exhausted,
  ) {
    if (exhausted.contains(volunteer.id)) return false;
    final dates = assignedDates[volunteer.id];
    if (dates == null || dates.isEmpty) return true;
    final minGap = volunteer.minimumIntervalWeeks * 7;
    for (final d in dates) {
      if (day.difference(d).inDays.abs() < minGap) return false;
    }
    return true;
  }

  void _recordAssignment(
    Volunteer volunteer,
    DateTime day,
    Map<String, List<DateTime>> assignedDates,
    Set<String> exhausted,
  ) {
    assignedDates.putIfAbsent(volunteer.id, () => []).add(day);
    if (!volunteer.canServeMultipleTimes) {
      exhausted.add(volunteer.id);
    }
  }

  List<DateTime> _eligibleDays(int month, int year, ServiceType serviceType) {
    final days = <DateTime>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final allowed = serviceType.weekdays;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      if (allowed.contains(date.weekday)) days.add(date);
    }
    return days;
  }
}
