import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/guardian_map_models.dart';
import 'guardian_map_repository.dart';

class ApiGuardianMapRepository implements GuardianMapRepository {
  ApiGuardianMapRepository({
    required this.baseUrl,
    required this.accessToken,
    required this.householdId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final String? householdId;
  final http.Client _client;

  @override
  Future<GuardianMapSnapshot> fetchMap() async {
    final activeHouseholdId = householdId;
    if (activeHouseholdId == null) {
      throw const GuardianMapRepositoryException('请先通过家庭码加入家庭');
    }
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/households/$activeHouseholdId/guardian-map'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    return GuardianMapSnapshot.fromJson(_decodeResponse(response));
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail'];
      final message = detail is Map<String, dynamic>
          ? detail['message'] as String? ?? '地图加载失败'
          : '地图加载失败';
      throw GuardianMapRepositoryException(message);
    }
    return decoded;
  }
}
