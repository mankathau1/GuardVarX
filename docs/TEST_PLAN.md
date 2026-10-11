# GUARDVARX — Master Verification & Test Plan
**Safety. Connected. | The Human Emergency Network**

## 1. Test Philosophy & Standards
In an emergency safety application, false negatives (failing to alert) and false positives (false rescue confirmations) can be catastrophic. The verification suite is built on these tenets:
- **No Mock-Only Confidence:** Business logic, database interactions, and state machines are validated against real executing logic, not trivial stub responses.
- **Explicit Failure Modes:** Every network call, serialization step, and permission prompt must have an explicit automated test validating the failure/recovery path.
- **Honest State Verification:** Tests ensure that the app never transitions to an optimistic state without server or hardware verification.

---

## 2. Test Pyramid & Coverage Targets

| Test Level | Scope | Technology | Target Coverage |
|---|---|---|---|
| **Backend Unit Tests** | Domain models, state machines, token verification, input validation, HMAC packet digests | Go `testing`, `testify` | > 85% |
| **Backend Integration Tests** | Chi routes, middleware pipeline, PostgreSQL repository layer, WebSocket hubs | Go `testing`, `httptest` | > 80% |
| **Mobile Unit & State Tests** | Riverpod notifiers, Drift SQLite outbox, offline queue, retry logic | Dart `test`, `flutter_test` | > 85% |
| **Mobile Widget Tests** | 3-second SOS deliberate hold, cancellation sheet, Safe Walk UI, accessibility contrast | `flutter_test` | Key flows |
| **Native Connectivity Tests** | BLE advertisement packet encoding/decoding, duplicate suppression, hop limit enforcement | Kotlin JUnit | Key protocols |

---

## 3. Go Backend Test Suites

### 3.1. Authentication & Security Tests (`backend/internal/auth`)
- `TestVerifyFirebaseToken_Valid`: Correctly extracts user claims and UID.
- `TestVerifyFirebaseToken_Expired`: Rejects expired token with HTTP 401.
- `TestVerifyFirebaseToken_Malformed`: Rejects spoofed/unsigned headers with HTTP 401.
- `TestObjectLevelAuthorization`: User B cannot access or cancel User A's incident (HTTP 403 / 404).

### 3.2. Emergency State Machine & Idempotency (`backend/internal/emergencies`)
- `TestCreateEmergency_Success`: Valid payload creates incident in `SERVER_RECEIVED` state.
- `TestCreateEmergency_Idempotent`: Duplicate POST with identical `Idempotency-Key` returns existing record without creating duplicate alerts or re-notifying contacts.
- `TestTransitionEmergency_ValidPath`: Valid flow `SERVER_RECEIVED` -> `CONTACT_NOTIFICATION_REQUESTED` -> `CONTACT_ACKNOWLEDGED` -> `RESOLVED`.
- `TestTransitionEmergency_InvalidPath`: Direct jump from `CANCELLED` to `RESOLVED` fails with `INVALID_STATE_TRANSITION`.
- `TestCancelEmergency_WithPIN`: Correct PIN cancels incident; incorrect PIN returns HTTP 401 and logs security event.

### 3.3. Safe Walk & Proximity Matching (`backend/internal/safe_walk`)
- `TestSafeWalk_CheckinInterval`: Overdue checkin triggers automated escalation to `WARNING` state.
- `TestSafeWalk_GracefulCompletion`: Destination reached triggers automatic closure and coordinate table cleanup.

### 3.4. WebSocket Real-Time Concurrency (`backend/internal/websocket`)
- `TestWebSocket_UnauthorizedConnection`: Rejects handshake without valid token.
- `TestWebSocket_TopicIsolation`: Events on `incident:A` are never received by clients subscribed only to `incident:B`.
- `TestWebSocket_PingPongHeartbeat`: Inactive client connection closed after 60s without ping.

---

## 4. Mobile Client & Flutter Test Suites

### 4.1. Offline Queue & Drift SQLite Persistence
- `TestSOS_PersistBeforeNetwork`: Verifies that SQLite record is created *before* the Dio HTTP client initiates the POST request.
- `TestSOS_NetworkFailureQueue`: If network throws `DioException.connectionTimeout`, status remains `QUEUED` and does not throw an uncaught error.
- `TestSOS_AutoRetryOnReconnect`: Connectivity restoration triggers background drain of queued outbox items.

### 4.2. Emergency Trigger UX (3-Second Deliberate Hold)
- `TestSOSButton_ShortTap_Ignored`: Quick tap does not trigger emergency alert (prevents pocket dials).
- `TestSOSButton_ThreeSecondHold_Success`: Pressing and holding for 3000ms triggers state change with haptic trigger.
- `TestSOSButton_ReleaseBeforeThreeSeconds_Cancelled`: Releasing at 2.5s cancels countdown and resets progress meter.

---

## 5. Android Native Connectivity & Hardware Edge Cases

| Scenario | Expected System Behavior | Verification Method |
|---|---|---|
| **Location Permission Denied** | App alerts user, disables continuous tracking, prompts manual landmark entry | Unit test + Widget test |
| **Bluetooth Disabled** | App notifies user that offline mesh relay is inactive; falls back to SMS / Internet | Channel integration test |
| **Airplane Mode / No Signal** | Incident saved locally, siren & offline emergency guidelines displayed, queued for auto-sync | Integration test |
| **Battery Saver Mode** | BLE scan interval throttled from 5s to 30s to preserve device power | Native Kotlin test |
| **App Process Killed** | Android Foreground Service keeps Safe Walk / SOS heartbeat running with notification | Instrumentation test |
| **Mesh Duplicate Packet** | Intermediary receives packet with known `IncidentUUID`; suppresses duplicate broadcast | Native Kotlin test |

---

## 6. Execution Commands

### Backend Verification:
```bash
cd backend
go test -v -race ./...
```

### Mobile Verification:
```bash
cd mobile
flutter analyze
flutter test
```
