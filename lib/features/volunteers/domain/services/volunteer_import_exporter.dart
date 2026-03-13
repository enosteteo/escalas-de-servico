import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../features/service_type/domain/enums/service_type.dart';
import '../models/volunteer.dart';

class VolunteerImportExporter {
  final _uuid = const Uuid();

  /// Serializes [volunteers] to a JSON string suitable for export.
  String exportToJson(List<Volunteer> volunteers) {
    final list = volunteers
        .map((v) => {
              'name': v.name,
              'age': v.age,
              'serviceTypes': v.serviceTypes.map((s) => s.name).toList(),
              'canServeMultipleTimes': v.canServeMultipleTimes,
              'minimumIntervalWeeks': v.minimumIntervalWeeks,
            })
        .toList();
    return jsonEncode(list);
  }

  /// Parses [jsonStr] and returns a list of [Volunteer] with fresh IDs.
  ///
  /// Throws [FormatException] if the JSON is invalid, not an array,
  /// or contains an unrecognised service type name.
  List<Volunteer> importFromJson(String jsonStr) {
    dynamic parsed;
    try {
      parsed = jsonDecode(jsonStr);
    } catch (_) {
      throw const FormatException('JSON inválido.');
    }

    if (parsed is! List) {
      throw const FormatException(
          'O arquivo deve conter uma lista de voluntários.');
    }

    return parsed.map<Volunteer>((item) {
      final name = item['name'] as String;
      final age = item['age'] as int?;
      final canServeMultipleTimes =
          item['canServeMultipleTimes'] as bool? ?? true;
      final minimumIntervalWeeks = item['minimumIntervalWeeks'] as int? ?? 1;

      final serviceTypesRaw =
          (item['serviceTypes'] as List?)?.cast<String>() ?? [];
      final serviceTypes = serviceTypesRaw.map((s) {
        final match = ServiceType.values.where((e) => e.name == s).toList();
        if (match.isEmpty) {
          throw FormatException('Tipo de serviço desconhecido: $s');
        }
        return match.first;
      }).toList();

      return Volunteer(
        id: _uuid.v4(),
        name: name,
        serviceTypes: serviceTypes,
        age: age,
        canServeMultipleTimes: canServeMultipleTimes,
        minimumIntervalWeeks: minimumIntervalWeeks,
      );
    }).toList();
  }
}
