import '../domain/guardian_map_models.dart';
import 'guardian_map_repository.dart';

class SmokeGuardianMapRepository implements GuardianMapRepository {
  const SmokeGuardianMapRepository();

  @override
  Future<GuardianMapSnapshot> fetchMap() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const GuardianMapSnapshot(
      mapId: 'smoke-map-home',
      mapVersion: 1,
      summary: GuardianMapSummary(
        completionPercent: 75,
        roomCount: 4,
        onlineDeviceCount: 2,
        unmonitoredRoomCount: 1,
      ),
      rooms: [
        GuardianRoom(
          id: 'room-living',
          name: '客厅',
          polygon: [
            MapPoint(x: 0, y: 0),
            MapPoint(x: 0.58, y: 0),
            MapPoint(x: 0.58, y: 0.61),
            MapPoint(x: 0, y: 0.61),
          ],
          labelPosition: MapPoint(x: 0.05, y: 0.05),
          scanStatus: RoomScanStatus.completed,
          monitoringStatus: RoomMonitoringStatus.active,
          privacyEnabled: false,
        ),
        GuardianRoom(
          id: 'room-kitchen',
          name: '厨房',
          polygon: [
            MapPoint(x: 0.58, y: 0),
            MapPoint(x: 1, y: 0),
            MapPoint(x: 1, y: 0.61),
            MapPoint(x: 0.58, y: 0.61),
          ],
          labelPosition: MapPoint(x: 0.63, y: 0.05),
          scanStatus: RoomScanStatus.completed,
          monitoringStatus: RoomMonitoringStatus.active,
          privacyEnabled: false,
        ),
        GuardianRoom(
          id: 'room-entry',
          name: '玄关',
          polygon: [
            MapPoint(x: 0, y: 0.61),
            MapPoint(x: 0.58, y: 0.61),
            MapPoint(x: 0.58, y: 1),
            MapPoint(x: 0, y: 1),
          ],
          labelPosition: MapPoint(x: 0.05, y: 0.66),
          scanStatus: RoomScanStatus.completed,
          monitoringStatus: RoomMonitoringStatus.active,
          privacyEnabled: false,
        ),
        GuardianRoom(
          id: 'room-bedroom',
          name: '卧室',
          polygon: [
            MapPoint(x: 0.58, y: 0.61),
            MapPoint(x: 1, y: 0.61),
            MapPoint(x: 1, y: 1),
            MapPoint(x: 0.58, y: 1),
          ],
          labelPosition: MapPoint(x: 0.63, y: 0.66),
          scanStatus: RoomScanStatus.template,
          monitoringStatus: RoomMonitoringStatus.unmonitored,
          privacyEnabled: true,
        ),
      ],
      devices: [
        GuardianDevice(
          id: 'smoke-camera-living',
          productModel: 'T8171',
          roomId: 'room-living',
          position: MapPoint(x: 0.34, y: 0.34),
          coverageRadius: 0.3,
          online: true,
        ),
        GuardianDevice(
          id: 'smoke-doorbell-entry',
          productModel: 'T8214',
          roomId: 'room-entry',
          zoneId: 'zone-front-door',
          position: MapPoint(x: 0.2, y: 0.85),
          coverageRadius: 0.22,
          online: true,
        ),
      ],
      events: [
        GuardianMapEvent(
          id: 'smoke-event-fall',
          eventType: 'fallDetected',
          severity: GuardianEventSeverity.info,
          roomId: 'room-living',
          position: MapPoint(x: 0.23, y: 0.18),
          title: '跌倒记录',
          subtitle: '昨日 · 已确认无碍',
          status: 'resolved',
        ),
        GuardianMapEvent(
          id: 'smoke-event-animal',
          eventType: 'animalDetected',
          severity: GuardianEventSeverity.warning,
          roomId: 'room-kitchen',
          position: MapPoint(x: 0.76, y: 0.3),
          title: '疑似小动物',
          subtitle: '厨房 · 3 条合并',
          status: 'pending',
        ),
        GuardianMapEvent(
          id: 'smoke-event-delivery',
          eventType: 'deliveryDetected',
          severity: GuardianEventSeverity.info,
          roomId: 'room-entry',
          zoneId: 'zone-front-door',
          position: MapPoint(x: 0.22, y: 0.84),
          title: '门口有外卖',
          subtitle: '18:12 · 待领取',
          status: 'pending',
        ),
      ],
      ankoPosition: MapPoint(x: 0.53, y: 0.55),
    );
  }
}
