import '../domain/auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<SmsChallenge> requestCode({
    required String countryCode,
    required String phoneNumber,
  });

  Future<AuthSession> verifyCode({
    required String challengeId,
    required String code,
    String? ankoAccount,
    String? nickname,
  });
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
