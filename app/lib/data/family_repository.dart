import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<FamilyOverview> fetchOverview();

  Future<JoinedFamily> joinFamily({
    required String familyCode,
    required String memberNickname,
  });

  Future<void> replaceEmergencyContacts({
    required String householdId,
    required List<EmergencyContactSelection> contacts,
  });
}

class FamilyRepositoryException implements Exception {
  const FamilyRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
