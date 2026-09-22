import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<FamilyOverview> fetchOverview();

  Future<JoinedFamily> joinFamily({
    required String familyCode,
    required String memberNickname,
  });

  Future<void> setEmergencyContact({
    required String householdId,
    required String contactId,
    required bool selected,
  });
}

class FamilyRepositoryException implements Exception {
  const FamilyRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
