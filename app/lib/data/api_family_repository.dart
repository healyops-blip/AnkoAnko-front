import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/family_models.dart';
import 'family_repository.dart';

class ApiFamilyRepository implements FamilyRepository {
  ApiFamilyRepository({
    required this.baseUrl,
    required this.accessToken,
    required this.householdId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  String? householdId;
  final http.Client _client;

  @override
  Future<FamilyOverview> fetchOverview() async {
    if (householdId == null) {
      throw const FamilyRepositoryException('请先通过家庭码加入家庭');
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/families/$householdId/contacts'),
      headers: _headers,
    );
    return FamilyOverview.fromJson(_decodeResponse(response));
  }

  @override
  Future<JoinedFamily> joinFamily({
    required String familyCode,
    required String memberNickname,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/families/join'),
      headers: _headers,
      body: jsonEncode({
        'familyCode': familyCode,
        'memberNickname': memberNickname,
      }),
    );
    final joined = JoinedFamily.fromJson(_decodeResponse(response));
    householdId = joined.internalId;
    return joined;
  }

  @override
  Future<void> replaceEmergencyContacts({
    required String householdId,
    required List<EmergencyContactSelection> contacts,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/v1/families/$householdId/emergency-contacts'),
      headers: _headers,
      body: jsonEncode({
        'contacts': contacts.map((contact) => contact.toJson()).toList(),
      }),
    );
    _decodeResponse(response);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail'];
      final message = detail is Map<String, dynamic>
          ? detail['message'] as String? ?? '请求失败'
          : '请求失败';
      throw FamilyRepositoryException(message);
    }
    return decoded;
  }
}
