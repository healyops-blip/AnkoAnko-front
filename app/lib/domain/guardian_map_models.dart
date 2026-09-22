class MapPoint {
  const MapPoint({required this.x, required this.y});

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  final double x;
  final double y;
}

enum RoomScanStatus { template, scanning, completed }

enum RoomMonitoringStatus { active, unmonitored }

enum GuardianEventSeverity { info, warning, critical }

class GuardianRoom {
  const GuardianRoom({
    required this.id,
    required this.name,
    required this.polygon,
    required this.labelPosition,
    required this.scanStatus,
    required this.monitoringStatus,
    required this.privacyEnabled,
  });

  factory GuardianRoom.fromJson(Map<String, dynamic> json) {
    return GuardianRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      polygon: (json['polygon'] as List<dynamic>)
          .map((point) => MapPoint.fromJson(point as Map<String, dynamic>))
          .toList(growable: false),
      labelPosition: MapPoint.fromJson(
        json['labelPosition'] as Map<String, dynamic>,
      ),
      scanStatus: RoomScanStatus.values.byName(json['scanStatus'] as String),
      monitoringStatus: RoomMonitoringStatus.values.byName(
        json['monitoringStatus'] as String,
      ),
      privacyEnabled: json['privacyEnabled'] as bool,
    );
  }

  final String id;
  final String name;
  final List<MapPoint> polygon;
  final MapPoint labelPosition;
  final RoomScanStatus scanStatus;
  final RoomMonitoringStatus monitoringStatus;
  final bool privacyEnabled;
}

class GuardianDevice {
  const GuardianDevice({
    required this.id,
    required this.productModel,
    required this.roomId,
    required this.position,
    required this.coverageRadius,
    required this.online,
    this.zoneId,
  });

  factory GuardianDevice.fromJson(Map<String, dynamic> json) {
    return GuardianDevice(
      id: json['id'] as String,
      productModel: json['productModel'] as String,
      roomId: json['roomId'] as String,
      zoneId: json['zoneId'] as String?,
      position: MapPoint.fromJson(json['position'] as Map<String, dynamic>),
      coverageRadius: (json['coverageRadius'] as num).toDouble(),
      online: json['online'] as bool,
    );
  }

  final String id;
  final String productModel;
  final String roomId;
  final String? zoneId;
  final MapPoint position;
  final double coverageRadius;
  final bool online;
}

class GuardianMapEvent {
  const GuardianMapEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.roomId,
    required this.position,
    required this.title,
    required this.subtitle,
    required this.status,
    this.zoneId,
  });

  factory GuardianMapEvent.fromJson(Map<String, dynamic> json) {
    return GuardianMapEvent(
      id: json['id'] as String,
      eventType: json['eventType'] as String,
      severity: GuardianEventSeverity.values.byName(json['severity'] as String),
      roomId: json['roomId'] as String,
      zoneId: json['zoneId'] as String?,
      position: MapPoint.fromJson(json['position'] as Map<String, dynamic>),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String eventType;
  final GuardianEventSeverity severity;
  final String roomId;
  final String? zoneId;
  final MapPoint position;
  final String title;
  final String subtitle;
  final String status;
}

class GuardianMapSnapshot {
  const GuardianMapSnapshot({
    required this.mapId,
    required this.mapVersion,
    required this.completionPercent,
    required this.rooms,
    required this.devices,
    required this.events,
    required this.ankoPosition,
  });

  factory GuardianMapSnapshot.fromJson(Map<String, dynamic> json) {
    return GuardianMapSnapshot(
      mapId: json['mapId'] as String,
      mapVersion: json['mapVersion'] as int,
      completionPercent: json['completionPercent'] as int,
      rooms: (json['rooms'] as List<dynamic>)
          .map((room) => GuardianRoom.fromJson(room as Map<String, dynamic>))
          .toList(growable: false),
      devices: (json['devices'] as List<dynamic>)
          .map(
            (device) => GuardianDevice.fromJson(device as Map<String, dynamic>),
          )
          .toList(growable: false),
      events: (json['events'] as List<dynamic>)
          .map(
            (event) => GuardianMapEvent.fromJson(event as Map<String, dynamic>),
          )
          .toList(growable: false),
      ankoPosition: MapPoint.fromJson(
        json['ankoPosition'] as Map<String, dynamic>,
      ),
    );
  }

  final String mapId;
  final int mapVersion;
  final int completionPercent;
  final List<GuardianRoom> rooms;
  final List<GuardianDevice> devices;
  final List<GuardianMapEvent> events;
  final MapPoint ankoPosition;

  int get onlineDeviceCount => devices.where((device) => device.online).length;

  int get unmonitoredRoomCount => rooms
      .where(
        (room) => room.monitoringStatus == RoomMonitoringStatus.unmonitored,
      )
      .length;
}
