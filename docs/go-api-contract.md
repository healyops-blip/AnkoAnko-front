# Anko Flutter ↔ Go API contract

The Flutter client reads the API origin from `ANKO_API_BASE_URL`. JSON field names
use lower camel case. Authenticated requests send `Authorization: Bearer <token>`.

Errors use this shape:

```json
{"detail":{"code":"STABLE_ERROR_CODE","message":"用户可读提示"}}
```

## SMS login and registration

`POST /v1/auth/sms/request`

```json
{"phoneCountryCode":"+86","phoneNumber":"13800001001"}
```

```json
{"challengeId":"uuid","retryAfterSeconds":60,"devCode":"123456"}
```

`devCode` is optional and must only be returned by a local development server.

`POST /v1/auth/sms/verify`

Existing-account login:

```json
{"challengeId":"uuid","code":"123456"}
```

New-account registration adds `ankoAccount` and `nickname`:

```json
{
  "challengeId":"uuid",
  "code":"123456",
  "ankoAccount":"dev_mom",
  "nickname":"妈妈"
}
```

Response:

```json
{
  "accessToken":"jwt-or-opaque-token",
  "tokenType":"bearer",
  "householdId":"uuid-or-null",
  "user":{
    "id":"uuid",
    "ankoAccount":"dev_mom",
    "nickname":"妈妈",
    "phoneMasked":"+86 **** 1001",
    "avatarUrl":null
  }
}
```

## Family contacts

`POST /v1/families/join`

```json
{"familyCode":"DEVANKO1","memberNickname":"妈妈"}
```

`GET /v1/families/{householdId}/contacts`

```json
{
  "householdId":"uuid",
  "householdName":"Anko开发家庭",
  "familyCode":"DEVANKO1",
  "members":[
    {
      "id":"uuid",
      "nickname":"妈妈",
      "memberNickname":"妈妈",
      "permissions":{"manageHousehold":true},
      "communicationMode":"standard",
      "phoneMasked":"+86 **** 1001",
      "isCurrentUser":true,
      "emergencyContactPriority":null,
      "avatarUrl":null
    }
  ]
}
```

There is no role, identity, or family-relationship field. The Go service should
distinguish administrator, elder, and child capabilities only through the
`permissions` object. Internal IDs are required for API actions but are never
rendered by the Flutter UI.

For the development environment, the Go service should seed one `DEVANKO1`
family containing all three test accounts:

| Phone | Anko account | Nickname | Permission profile |
| --- | --- | --- | --- |
| `+86 13800001001` | `dev_mom` | 妈妈 | Family administrator; can invite, edit and manage the family |
| `+86 13800001002` | `dev_grandma` | 奶奶 | Member; can configure personal emergency contacts |
| `+86 13800001003` | `dev_child` | 孩子 | Restricted member; cannot manage the family or inspect event evidence |

These labels are test data, not values in a role/identity column.

## Emergency contacts

`PUT /v1/families/{householdId}/emergency-contacts`

```json
{
  "contacts":[
    {"contactMemberId":"uuid-mom","priority":1},
    {"contactMemberId":"uuid-child","priority":2}
  ]
}
```

```json
{
  "contacts":[
    {"contactMemberId":"uuid-mom","priority":1},
    {"contactMemberId":"uuid-child","priority":2}
  ]
}
```

The service must replace both slots atomically, derive the owner from the bearer
token, reject self-selection and duplicate members, accept only priorities `1`
and `2`, and ensure every selected member belongs to the same family. Sending an
empty `contacts` list clears both slots. The contacts response exposes each
member's slot as `emergencyContactPriority`; unselected members return `null`.

## 2D guardian map

`GET /v1/households/{householdId}/guardian-map`

This endpoint returns normalized 2D map data. Coordinates and coverage radii
use the `0.0` to `1.0` range and must not contain device-screen pixels. The
Flutter client uses the same payload for every screen size.

```json
{
  "mapId":"map-home",
  "mapVersion":1,
  "summary":{
    "completionPercent":75,
    "roomCount":4,
    "onlineDeviceCount":2,
    "unmonitoredRoomCount":1
  },
  "rooms":[
    {
      "id":"room-living",
      "name":"客厅",
      "polygon":[
        {"x":0.0,"y":0.0},
        {"x":0.58,"y":0.0},
        {"x":0.58,"y":0.61},
        {"x":0.0,"y":0.61}
      ],
      "labelPosition":{"x":0.05,"y":0.05},
      "scanStatus":"completed",
      "monitoringStatus":"active",
      "privacyEnabled":false
    }
  ],
  "devices":[
    {
      "id":"device-camera-1",
      "productModel":"T8171",
      "roomId":"room-living",
      "zoneId":null,
      "position":{"x":0.34,"y":0.34},
      "coverageRadius":0.3,
      "online":true
    }
  ],
  "events":[
    {
      "id":"event-1",
      "eventType":"fallDetected",
      "severity":"info",
      "roomId":"room-living",
      "zoneId":null,
      "position":{"x":0.23,"y":0.18},
      "title":"跌倒记录",
      "subtitle":"昨日 · 已确认无碍",
      "status":"resolved"
    }
  ],
  "ankoPosition":{"x":0.53,"y":0.55}
}
```

`summary` is required and is the authoritative source for the guardian card's
headline values. The Flutter client displays these four values directly and
does not recalculate them from `rooms` or `devices`. The detailed arrays remain
required because they drive map geometry, device coverage and event markers.

Allowed room values:

- `scanStatus`: `template`, `scanning`, `completed`
- `monitoringStatus`: `active`, `unmonitored`
- `severity`: `info`, `warning`, `critical`

The 2D response intentionally contains no GLB, glTF or USDZ URL. A future 3D
viewer and a real-time device-event stream will use separate contracts so the
guardian card remains lightweight.
