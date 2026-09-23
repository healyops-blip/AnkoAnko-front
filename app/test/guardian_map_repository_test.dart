import 'dart:convert';

import 'package:anko_anko/data/api_guardian_map_repository.dart';
import 'package:anko_anko/data/smoke_guardian_map_repository.dart';
import 'package:anko_anko/domain/guardian_map_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('smoke map exposes normalized 2D rooms, devices and events', () async {
    final map = await const SmokeGuardianMapRepository().fetchMap();

    expect(map.summary.completionPercent, 75);
    expect(map.summary.roomCount, 4);
    expect(map.rooms, hasLength(4));
    expect(map.summary.onlineDeviceCount, 2);
    expect(map.summary.unmonitoredRoomCount, 1);
    expect(map.events, isNotEmpty);
    expect(
      map.rooms.expand((room) => room.polygon),
      everyElement(
        isA<MapPoint>()
            .having((point) => point.x, 'x', inInclusiveRange(0, 1))
            .having((point) => point.y, 'y', inInclusiveRange(0, 1)),
      ),
    );
  });

  test('API map repository calls the reserved Go endpoint', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode(_apiResponse),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repository = ApiGuardianMapRepository(
      baseUrl: 'https://api.example.test',
      accessToken: 'test-token',
      householdId: 'family-1',
      client: client,
    );

    final map = await repository.fetchMap();

    expect(
      capturedRequest.url.toString(),
      'https://api.example.test/v1/households/family-1/guardian-map',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer test-token');
    expect(map.mapId, 'map-1');
    expect(map.summary.roomCount, 1);
    expect(map.summary.onlineDeviceCount, 1);
    expect(map.rooms.single.name, '客厅');
    expect(map.events.single.severity, GuardianEventSeverity.warning);
  });
}

const _apiResponse = {
  'mapId': 'map-1',
  'mapVersion': 2,
  'summary': {
    'completionPercent': 100,
    'roomCount': 1,
    'onlineDeviceCount': 1,
    'unmonitoredRoomCount': 0,
  },
  'rooms': [
    {
      'id': 'room-1',
      'name': '客厅',
      'polygon': [
        {'x': 0, 'y': 0},
        {'x': 1, 'y': 0},
        {'x': 1, 'y': 1},
      ],
      'labelPosition': {'x': 0.1, 'y': 0.1},
      'scanStatus': 'completed',
      'monitoringStatus': 'active',
      'privacyEnabled': false,
    },
  ],
  'devices': [
    {
      'id': 'device-1',
      'productModel': 'T8171',
      'roomId': 'room-1',
      'zoneId': null,
      'position': {'x': 0.5, 'y': 0.5},
      'coverageRadius': 0.25,
      'online': true,
    },
  ],
  'events': [
    {
      'id': 'event-1',
      'eventType': 'animalDetected',
      'severity': 'warning',
      'roomId': 'room-1',
      'zoneId': null,
      'position': {'x': 0.6, 'y': 0.4},
      'title': '疑似小动物',
      'subtitle': '厨房 · 待确认',
      'status': 'pending',
    },
  ],
  'ankoPosition': {'x': 0.5, 'y': 0.5},
};
