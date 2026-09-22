# Flutter Smoke mode

Smoke mode runs the normal Flutter screens against deterministic in-memory
repositories. It makes no network requests and writes no local database.

```bash
cd app
flutter run --dart-define=ANKO_SMOKE_MODE=true
```

Debug builds default to Smoke mode. Release builds default to API mode. The
orange `SMOKE` banner remains visible while Smoke data is active.

## Accounts

All accounts use verification code `123456`.

| Phone | Anko account | Display name |
| --- | --- | --- |
| `13800001001` | `dev_mom` | 妈妈 |
| `13800001002` | `dev_grandma` | 奶奶 |
| `13800001003` | `dev_child` | 孩子 |

The shared family code is `DEVANKO1`. State changes survive only for the current
app process and reset after restart.

## Go API mode

```bash
flutter run \
  --dart-define=ANKO_SMOKE_MODE=false \
  --dart-define=ANKO_API_BASE_URL=http://127.0.0.1:8080
```

API mode never falls back to Smoke data. If the Go API address is missing, the
app displays a configuration error. See [go-api-contract.md](go-api-contract.md)
for request and response fields.
