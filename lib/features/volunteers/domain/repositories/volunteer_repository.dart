import '../models/volunteer.dart';

abstract class VolunteerRepository {
  Future<List<Volunteer>> getAll();
  Future<void> save(Volunteer volunteer);
  Future<void> delete(String id);
  Future<bool> existsByName(String name);
}
