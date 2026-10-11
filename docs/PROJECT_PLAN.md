# GUARDVARX — Master Project Plan
**Safety. Connected. | The Human Emergency Network**

## 1. Executive Summary & Goals
GuardVarX is an emergency safety platform designed for high-stress, low-connectivity scenarios across India, specifically targeting vulnerable situations (women traveling alone, night workers, senior citizens, students, and accident victims).

The project is built on ten core engineering and product principles:
1. **Safety before engagement and monetization.**
2. **Privacy by default:** Zero unnecessary data retention; location sharing is strictly consensual and revocable.
3. **Clear consent:** Fine-grained control over when, how, and with whom location is shared.
4. **Honest communication:** Never display false "connected" or "protected" states. Explicit distinction between "stored locally", "queued", "relayed", "server received", and "acknowledged".
5. **Accessible emergency controls:** Prominent, high-contrast, hold-to-activate (3-second deliberate hold), light-independent contrast, screen-reader friendly.
6. **Minimal battery consumption:** Intelligent BLE scanning cycles, geofence-based transitions, sleep-aware background operations.
7. **Secure data storage:** Platform-backed Android Keystore / EncryptedSharedPreferences on device; parameterized queries, TLS, and strict role-based access control (RBAC) on the backend.
8. **Long-term maintainability:** Modular monolith backend in Go (Chi router, pgx, SQL migrations); Flutter Material 3 with Riverpod and GoRouter.
9. **Graceful degradation:** Offline-first architecture with local SQLite (Drift) persistence, store-and-forward mesh via BLE/Wi-Fi Direct, and fallback emergency guidance (e.g. 112 India emergency numbers, loud siren, offline instructions).
10. **No false promises:** Explicit disclaimer that GuardVarX augments—rather than replaces—official Indian emergency services (112, 100, 108, 1091).

---

## 2. Target Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                          GuardVarX Ecosystem                           │
└────────────────────────────────────────────────────────────────────────┘
          │                                                    │
┌─────────▼───────────────────────────┐      ┌─────────────────▼─────────┐
│     Mobile App (Flutter + Dart)     │      │   Go Chi Backend Server   │
│ - Material 3 Liquid Glass UI        │      │ - Chi Router (v1 API)     │
│ - Riverpod State Management         │◄────►│ - PostgreSQL + pgx        │
│ - GoRouter Navigation               │ REST │ - JWT / Firebase Auth     │
│ - SQLite (Drift) Offline Engine     │  +   │ - Real-time WebSocket Hub │
│ - Android Kotlin Platform Channels  │  WS  │ - Structured slog Logger  │
│   (BLE, Wi-Fi Direct, SMS Fallback) │      │ - Rate Limiting & Audit   │
└─────────────────────────────────────┘      └───────────────────────────┘
          │                                                    │
          ▼                                                    ▼
┌─────────────────────────────────────┐      ┌───────────────────────────┐
│     Native Android (Kotlin)         │      │     PostgreSQL Database   │
│ - BLE Peripheral (Advertiser)       │      │ - Incidents & Events      │
│ - BLE Central (Scanner/Relay)       │      │ - Users & Devices         │
│ - Foreground Service (Safe Walk)    │      │ - Trusted Contacts        │
│ - Android Keystore                  │      │ - Missions & Responders   │
└─────────────────────────────────────┘      └───────────────────────────┘
```

---

## 3. Implementation Phases & Milestones

### Phase 1: Foundation, Architecture & Repository Setup (Current)
- [x] Repository discovery and environment assessment.
- [x] Comprehensive architectural, API, security, and test specifications.
- [ ] Initialize Go Backend (`backend/`) with Chi router, health/readiness probes, configuration loading, structured logging (`slog`), and versioned SQL migrations (`backend/migrations/`).
- [ ] Initialize Flutter Android App (`mobile/`) with Material 3 Apple Liquid Glass design tokens, Riverpod, GoRouter, Dio client, and Drift SQLite offline persistence.
- [ ] Implement initial unit and integration tests.

### Phase 2: Identity, Trusted Contacts & SOS MVP
- [ ] User profile and device registration APIs with Firebase ID token authentication middleware.
- [ ] Trusted contacts management with phone verification and consent workflows.
- [ ] SOS incident creation, local SQLite queue, idempotency key generation, and upload sync.
- [ ] SOS delivery state machine: `CREATED` -> `LOCAL_SAVED` -> `QUEUED` -> `SENDING` -> `SERVER_RECEIVED` -> `CONTACT_NOTIFICATION_REQUESTED` -> `CONTACT_ACKNOWLEDGED`.
- [ ] Push notification orchestration (FCM) to trusted contacts.

### Phase 3: Real-Time Communication & Safe Walk
- [ ] Authenticated WebSocket channel for incident live updates, helper dispatch, and acknowledgements.
- [ ] Safe Walk journey tracking:
  - Destination selection and route estimation.
  - Periodic check-in timers with audio/haptic prompts.
  - Automatic escalation upon missed check-in.
  - Consensual, time-bounded location sharing.
- [ ] Nearby helper availability discovery and responder mission lifecycle.

### Phase 4: Native Offline & Store-and-Forward Mesh (Android Kotlin)
- [ ] Kotlin Android platform channel interface (`GuardVarXConnectivityChannel`).
- [ ] BLE Peripheral advertisement of compact, authenticated emergency packets.
- [ ] BLE Central scanning with battery-aware duty cycling.
- [ ] Store-and-forward mesh relay protocol with hop limits (max 3), TTL expiration, and duplicate suppression caches.
- [ ] Fallback SMS dispatcher with user confirmation and emergency siren trigger.

### Phase 5: Community Safety, Moderation & Privacy
- [ ] Community reports (hazard warnings, missing persons, road accidents).
- [ ] Moderation engine: rate limiting, spam prevention, reporting/blocking malicious accounts.
- [ ] Sensitive data anonymization and strict coordinate fuzzing for public community feeds.
- [ ] Automated TTL data pruning for expired locations and resolved incidents.

### Phase 6: Production Hardening & Verification
- [ ] End-to-end integration tests between mobile client and Go backend.
- [ ] Security audit: OWASP API Top 10 compliance, input validation, SQL injection prevention, replay attack mitigation.
- [ ] Performance and load benchmarks for WebSocket concurrency and emergency incident ingestion.
- [ ] Real-device scenario testing (airplane mode, permission revocation, battery saver, screen off).

---

## 4. Definition of Done
A feature is only considered done when:
1. Complete, non-mocked implementation exists in the codebase.
2. Data models, invariants, and API endpoints are fully documented.
3. Authentication, object-level authorization, and input validation are strictly enforced.
4. Offline storage, network retry, and edge cases are handled.
5. Automated tests (unit, integration, or widget) exist and pass.
6. Honest status reporting is maintained (no simulated delivery confirmations).
