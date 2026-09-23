import '../domain/guardian_map_models.dart';

abstract interface class GuardianMapRepository {
  Future<GuardianMapSnapshot> fetchMap();
}

class ConfigurationGuardianMapRepository implements GuardianMapRepository {
  const ConfigurationGuardianMapRepository(this.message);

  final String message;

  @override
  Future<GuardianMapSnapshot> fetchMap() =>
      Future.error(GuardianMapRepositoryException(message));
}

class GuardianMapRepositoryException implements Exception {
  const GuardianMapRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
