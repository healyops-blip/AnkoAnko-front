import 'package:flutter/foundation.dart';

import '../domain/auth_models.dart';
import 'api_auth_repository.dart';
import 'api_family_repository.dart';
import 'auth_repository.dart';
import 'configuration_auth_repository.dart';
import 'family_repository.dart';
import 'smoke_auth_repository.dart';
import 'smoke_data_store.dart';
import 'smoke_family_repository.dart';

class RuntimeServices {
  const RuntimeServices({
    required this.smokeMode,
    required this.authRepository,
    required this.familyRepositoryFactory,
  });

  final bool smokeMode;
  final AuthRepository authRepository;
  final FamilyRepository Function(AuthSession session) familyRepositoryFactory;
}

RuntimeServices createRuntimeServices({
  bool? smokeModeOverride,
  String? apiBaseUrlOverride,
}) {
  const configuredSmokeMode = bool.fromEnvironment(
    'ANKO_SMOKE_MODE',
    defaultValue: kDebugMode,
  );
  const configuredApiBaseUrl = String.fromEnvironment('ANKO_API_BASE_URL');
  final smokeMode = smokeModeOverride ?? configuredSmokeMode;
  final apiBaseUrl = apiBaseUrlOverride ?? configuredApiBaseUrl;

  if (smokeMode) {
    final store = SmokeDataStore();
    return RuntimeServices(
      smokeMode: true,
      authRepository: SmokeAuthRepository(store: store),
      familyRepositoryFactory: (session) =>
          SmokeFamilyRepository(store: store, session: session),
    );
  }
  if (apiBaseUrl.isEmpty) {
    const message = '正式模式缺少 ANKO_API_BASE_URL，请配置 Go 后端地址。';
    return RuntimeServices(
      smokeMode: false,
      authRepository: const ConfigurationAuthRepository(message),
      familyRepositoryFactory: (_) =>
          throw const AppConfigurationException(message),
    );
  }
  return RuntimeServices(
    smokeMode: false,
    authRepository: ApiAuthRepository(
      baseUrl: apiBaseUrl,
      initialAccessToken: const String.fromEnvironment('ANKO_ACCESS_TOKEN'),
      initialHouseholdId: const String.fromEnvironment('ANKO_HOUSEHOLD_ID'),
      initialNickname: const String.fromEnvironment('ANKO_NICKNAME'),
      initialAnkoAccount: const String.fromEnvironment('ANKO_ACCOUNT'),
    ),
    familyRepositoryFactory: (session) => ApiFamilyRepository(
      baseUrl: apiBaseUrl,
      accessToken: session.accessToken,
      householdId: session.householdId,
    ),
  );
}
