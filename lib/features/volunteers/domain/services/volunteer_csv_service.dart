import 'package:uuid/uuid.dart';

import '../../../../features/service_type/domain/enums/service_type.dart';
import '../models/volunteer.dart';

/// Handles CSV export and import of volunteers.
///
/// CSV format (comma-separated, pipe-delimited service types):
///   Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas
///   Ana,15,weekendService,true,1
///   Bia,,sundayOnly|fridayOnly,false,2
class VolunteerCsvService {
  static const _header =
      'Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas';

  final _uuid = const Uuid();

  /// Serializes [volunteers] to a CSV string with a header row.
  String export(List<Volunteer> volunteers) {
    final buffer = StringBuffer()..writeln(_header);
    for (final v in volunteers) {
      final age = v.age?.toString() ?? '';
      final types = v.serviceTypes.map((s) => s.name).join('|');
      buffer.writeln(
          '${v.name},$age,$types,${v.canServeMultipleTimes},${v.minimumIntervalWeeks}');
    }
    return buffer.toString();
  }

  /// Parses [csv] and returns a list of [Volunteer] with fresh IDs.
  ///
  /// Rows with wrong column count or unknown service types are silently skipped.
  List<Volunteer> import(String csv) {
    final lines = csv.trim().split('\n');
    if (lines.isEmpty) return [];

    final result = <Volunteer>[];

    // Skip header (first line)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = line.split(',');
      if (cols.length != 5) continue;

      final name = cols[0].trim();
      if (name.isEmpty) continue;

      final age = cols[1].trim().isEmpty ? null : int.tryParse(cols[1].trim());
      final canServe = cols[3].trim().toLowerCase() == 'true';
      final interval = int.tryParse(cols[4].trim()) ?? 1;

      final typeNames = cols[2].trim().split('|');
      final serviceTypes = <ServiceType>[];
      bool validTypes = true;
      for (final t in typeNames) {
        final match =
            ServiceType.values.where((e) => e.name == t.trim()).toList();
        if (match.isEmpty) {
          validTypes = false;
          break;
        }
        serviceTypes.add(match.first);
      }
      if (!validTypes || serviceTypes.isEmpty) continue;

      result.add(Volunteer(
        id: _uuid.v4(),
        name: name,
        serviceTypes: serviceTypes,
        age: age,
        canServeMultipleTimes: canServe,
        minimumIntervalWeeks: interval,
      ));
    }

    return result;
  }
}
