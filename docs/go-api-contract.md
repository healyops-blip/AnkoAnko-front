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
      "isEmergencyContact":false,
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

`PUT /v1/families/{householdId}/emergency-contacts/{contactMemberId}`

```json
{"selected":true}
```

```json
{"contactMemberId":"uuid","selected":true}
```

The service must derive the owner of this setting from the bearer token, reject
self-selection, and ensure both members belong to the same family.
