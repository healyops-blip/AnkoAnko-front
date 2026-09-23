import 'dart:convert';

import 'package:anko_anko/data/api_family_repository.dart';
import 'package:anko_anko/domain/family_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('API replaces both emergency contact slots atomically', () async {
    late http.Request capturedRequest;
    final repository = ApiFamilyRepository(
      baseUrl: 'https://api.example.test',
      accessToken: 'test-token',
      householdId: 'family-1',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      }),
    );

    await repository.replaceEmergencyContacts(
      householdId: 'family-1',
      contacts: const [
        EmergencyContactSelection(contactMemberId: 'member-1', priority: 1),
        EmergencyContactSelection(contactMemberId: 'member-2', priority: 2),
      ],
    );

    expect(
      capturedRequest.url.toString(),
      'https://api.example.test/v1/families/family-1/emergency-contacts',
    );
    expect(capturedRequest.method, 'PUT');
    expect(jsonDecode(capturedRequest.body), {
      'contacts': [
        {'contactMemberId': 'member-1', 'priority': 1},
        {'contactMemberId': 'member-2', 'priority': 2},
      ],
    });
  });
}
