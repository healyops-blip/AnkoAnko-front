import '../domain/auth_models.dart';
import 'auth_repository.dart';

class AppConfigurationException implements Exception {
  const AppConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ConfigurationAuthRepository implements AuthRepository {
  const ConfigurationAuthRepository(this.message);

  final String message;

  @override
  Future<AuthSession?> restoreSession() =>
      Future.error(AppConfigurationException(message));

  @override
  Future<SmsChallenge> requestCode({
    required String countryCode,
    required String phoneNumber,
  }) => Future.error(AppConfigurationException(message));

  @override
  Future<AuthSession> verifyCode({
    required String challengeId,
    required String code,
    String? ankoAccount,
    String? nickname,
  }) => Future.error(AppConfigurationException(message));
}
