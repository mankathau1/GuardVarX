# GuardVarX
> **Safety. Connected. | The Human Emergency Network**

GuardVarX is a privacy-first, offline-resilient emergency safety platform for India, with a dedicated focus on women's safety, night-commute protection, senior citizens, and community-assisted response.

---

## Architecture at a Glance

- **Mobile Client (`mobile/`):** Flutter + Dart with custom Material 3 Apple Liquid Glass design system, Riverpod 2.x state management, GoRouter, Dio HTTP with automatic retry, Drift SQLite for offline-first persistence, and Kotlin Android platform channels.
- **Android Connectivity (`android-connectivity/` & `mobile/android/`):** Kotlin native platform channel for BLE peripheral advertising, BLE central scanning with battery-aware duty cycling, store-and-forward mesh relay, and foreground service.
- **Backend API (`backend/`):** Go (Golang 1.24+) modular monolith with Chi HTTP router, PostgreSQL 16 (pgxpool), versioned SQL migrations, real-time WebSocket hub, Firebase token verification, and structured `slog` logging.
- **Documentation (`docs/`):**
  - [PROJECT_PLAN.md](file:///docs/PROJECT_PLAN.md)
  - [ARCHITECTURE.md](file:///docs/ARCHITECTURE.md)
  - [SECURITY_AND_PRIVACY.md](file:///docs/SECURITY_AND_PRIVACY.md)
  - [API_SPEC.md](file:///docs/API_SPEC.md)
  - [TEST_PLAN.md](file:///docs/TEST_PLAN.md)

---

## Getting Started

### Prerequisites
- Go 1.24+
- Flutter 3.27+ / Dart 3.6+
- Docker & Docker Compose (optional, for local PostgreSQL)

### Running Backend Locally
```bash
cd backend
go mod download
go run cmd/api/main.go
```

### Running Backend Tests
```bash
cd backend
go test -v -race ./...
```

### Running Mobile App
```bash
cd mobile
flutter pub get
flutter test
flutter run
```

---

## Ten Core Engineering Principles
1. Safety before engagement and monetization.
2. Privacy by default.
3. Clear consent for location sharing.
4. Honest communication about delivery and connectivity.
5. Accessible emergency controls.
6. Minimal battery consumption.
7. Secure data storage.
8. Long-term maintainability.
9. Graceful failure when services are unavailable.
10. No false promises of guaranteed rescue.
