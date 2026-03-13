import '../../../service_type/domain/enums/service_type.dart';

class VolunteerValidator {
  String? validateName(String name) {
    if (name.trim().isEmpty) return 'O nome não pode ser vazio.';
    return null;
  }

  String? validateServiceTypes(List<ServiceType> serviceTypes) {
    if (serviceTypes.isEmpty) return 'Selecione pelo menos um tipo de culto.';
    return null;
  }
}
