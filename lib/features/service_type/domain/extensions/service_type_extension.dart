import '../enums/service_type.dart';

extension ServiceTypeExtension on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.weekendService:
        return 'Fim de Semana';
      case ServiceType.sundayOnly:
        return 'Apenas Domingo';
      case ServiceType.fridayOnly:
        return 'Apenas Sexta';
    }
  }

  List<int> get weekdays {
    switch (this) {
      case ServiceType.weekendService:
        return List.unmodifiable([6, 7]);
      case ServiceType.sundayOnly:
        return List.unmodifiable([7]);
      case ServiceType.fridayOnly:
        return List.unmodifiable([5]);
    }
  }
}
