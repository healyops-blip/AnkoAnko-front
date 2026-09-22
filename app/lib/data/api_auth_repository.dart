import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_models.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this.baseUrl,
    this.initialAccessToken = '',
    this.initialHouseholdId = '',
    this.initialNickname = '',
    this.initialAnkoAccount = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String initialAccessToken;
  final String initialHouseholdId;
  final String initialNickname;
  final String initialAnkoAccount;
  final http.Client _client;

  @override
  Future<AuthSession?> restoreSession() async {
    if (initialAccessToken.isEmpty) return null;
    return AuthSession(
      accessToken: initialAccessToken,
      ankoAccount: initialAnkoAccount,
      householdId: initialHouseholdId.isEmpty ? null : initialHouseholdId,
      nickname: initialNickname,
    );
  }

  @override
  Future<SmsChallenge> requestCode({
    required String countryCode,
    required String phoneNumber,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/sms/request'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneCountryCode': countryCode,
        'phoneNumber': phoneNumber,
      }),
    );
    return SmsChallenge.fromJson(_decodeResponse(response));
  }

  @override
  Future<AuthSession> verifyCode({
    required String challengeId,
    required String code,
    String? ankoAccount,
    String? nickname,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/sms/verify'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'challengeId': challengeId,
        'code': code,
        'ankoAccount': ?ankoAccount,
        'nickname': ?nickname,
      }),
    );
    return AuthSession.fromJson(_decodeResponse(response));
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail'];
      final message = detail is Map<String, dynamic>
          ? detail['message'] as String? ?? '请求失败'
          : '请求失败';
      throw AuthRepositoryException(message);
    }
    return decoded;
  }
}
