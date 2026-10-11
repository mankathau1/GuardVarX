# GUARDVARX — REST & WebSocket API Specification (v1)
**Safety. Connected. | The Human Emergency Network**

Base URL: `/api/v1`  
All timestamps are ISO 8601 UTC strings (`YYYY-MM-DDTHH:MM:SSZ`).  
All authenticated endpoints require `Authorization: Bearer <token>`.

---

## 1. Standard Error Envelope
All error responses adhere to RFC 7807 (Problem Details):
```json
{
  "error": {
    "code": "INVALID_STATE_TRANSITION",
    "message": "Cannot resolve an incident that is currently in CANCELLED state.",
    "request_id": "c1f7b8a2-3f8d-4a1e-84b2-9df73e6a109a",
    "details": {
      "current_status": "CANCELLED",
      "attempted_status": "RESOLVED"
    }
  }
}
```

---

## 2. Health & Readiness Probes

### GET `/health`
- **Description:** Basic liveness check.
- **Auth:** None
- **Response 200 OK:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2026-10-11T10:00:00Z"
}
```

### GET `/ready`
- **Description:** Readiness check verifying database connectivity.
- **Auth:** None
- **Response 200 OK:**
```json
{
  "status": "ready",
  "database": "connected",
  "migrations": "up_to_date"
}
```
- **Response 503 Service Unavailable:** If PostgreSQL connection fails.

---

## 3. User & Device Management

### GET `/api/v1/me`
- **Description:** Retrieve current authenticated user profile.
- **Auth:** Required
- **Response 200 OK:**
```json
{
  "id": "usr_94f8841a-e99d-4876-b673-cfa6a048705b",
  "firebase_uid": "fb_abc123456789",
  "phone": "+919876543210",
  "display_name": "Priya Sharma",
  "email": "priya.sharma@example.com",
  "avatar_url": null,
  "role": "STANDARD_USER",
  "emergency_pin_set": true,
  "created_at": "2026-10-01T04:30:00Z",
  "updated_at": "2026-10-10T12:00:00Z"
}
```

### PUT `/api/v1/me`
- **Description:** Update user profile details.
- **Request Body:**
```json
{
  "display_name": "Priya Sharma",
  "avatar_url": "https://guardvarx-storage.example.com/avatars/usr_123.jpg"
}
```
- **Response 200 OK:** Updated user profile.

### DELETE `/api/v1/me`
- **Description:** Permanently delete account and associated personal data.
- **Response 204 No Content**

### POST `/api/v1/devices`
- **Description:** Register or update device push token (FCM).
- **Request Body:**
```json
{
  "device_id": "android_98a76b5c4d3e2f1a",
  "fcm_token": "fcm_token_sample_string_123456789",
  "platform": "android",
  "model": "Samsung Galaxy S24",
  "os_version": "Android 15"
}
```
- **Response 200 OK:**
```json
{
  "id": "dev_38fbc921-23d5-4561-9c32-a5893d567119",
  "status": "registered",
  "updated_at": "2026-10-11T10:00:00Z"
}
```

---

## 4. Trusted Contacts

### GET `/api/v1/trusted-contacts`
- **Description:** List configured trusted contacts.
- **Response 200 OK:**
```json
[
  {
    "id": "tc_550e8400-e29b-41d4-a716-446655440000",
    "name": "Arun Sharma (Brother)",
    "phone": "+919812345678",
    "relationship": "Brother",
    "is_confirmed": true,
    "can_view_safe_walk": true,
    "can_receive_sos": true,
    "priority_order": 1,
    "created_at": "2026-10-01T04:30:00Z"
  }
]
```

### POST `/api/v1/trusted-contacts`
- **Description:** Add a new trusted contact.
- **Request Body:**
```json
{
  "name": "Kavita (Friend)",
  "phone": "+919876501234",
  "relationship": "Friend",
  "can_view_safe_walk": true,
  "can_receive_sos": true,
  "priority_order": 2
}
```
- **Response 201 Created**

### DELETE `/api/v1/trusted-contacts/{id}`
- **Description:** Remove a trusted contact.
- **Response 204 No Content**

---

## 5. Emergency SOS Management

### POST `/api/v1/emergencies`
- **Description:** Submit an SOS emergency alert.
- **Header:** `Idempotency-Key: <UUID>`
- **Request Body:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "emergency_type": "PERSONAL_THREAT",
  "message": "Immediate danger near Sector 18 metro station.",
  "latitude": 28.570774,
  "longitude": 77.327107,
  "accuracy_meters": 8.5,
  "location_timestamp": "2026-10-11T10:00:15Z",
  "priority": "HIGH",
  "protocol_version": 1
}
```
- **Response 201 Created:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "status": "SERVER_RECEIVED",
  "server_timestamp": "2026-10-11T10:00:16Z",
  "receipt_id": "rcpt_98234120-d4fa-48ef-a332-901456bf8912",
  "contacts_notified_count": 2,
  "helpers_matched_count": 1
}
```

### GET `/api/v1/emergencies/{id}`
- **Description:** Get live status and tracking details for an incident.
- **Response 200 OK:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "sender_id": "usr_94f8841a-e99d-4876-b673-cfa6a048705b",
  "emergency_type": "PERSONAL_THREAT",
  "status": "HELPER_EN_ROUTE",
  "latitude": 28.570774,
  "longitude": 77.327107,
  "accuracy_meters": 8.5,
  "created_at": "2026-10-11T10:00:15Z",
  "updated_at": "2026-10-11T10:02:40Z",
  "active_helpers": [
    {
      "helper_id": "hlp_12345",
      "status": "EN_ROUTE",
      "distance_meters": 350,
      "eta_minutes": 3
    }
  ]
}
```

### POST `/api/v1/emergencies/{id}/cancel`
- **Description:** Cancel an active emergency with optional confirmation PIN.
- **Request Body:**
```json
{
  "reason": "Accidental trigger, all safe.",
  "pin": "1234"
}
```
- **Response 200 OK:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "status": "CANCELLED",
  "cancelled_at": "2026-10-11T10:05:00Z"
}
```

### POST `/api/v1/emergencies/{id}/resolve`
- **Description:** Mark incident as successfully resolved.
- **Response 200 OK:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "status": "RESOLVED",
  "resolved_at": "2026-10-11T10:15:00Z"
}
```

### POST `/api/v1/emergencies/{id}/acknowledgements`
- **Description:** Trusted contact acknowledges alert.
- **Response 200 OK:**
```json
{
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "acknowledged_by": "tc_550e8400-e29b-41d4-a716-446655440000",
  "acknowledged_at": "2026-10-11T10:01:05Z"
}
```

---

## 6. Safe Walk Sessions

### POST `/api/v1/safe-walks`
- **Description:** Initiate a monitored Safe Walk journey.
- **Request Body:**
```json
{
  "destination_name": "Home, Sector 62",
  "destination_latitude": 28.6275,
  "destination_longitude": 77.3649,
  "expected_duration_minutes": 25,
  "checkin_interval_minutes": 10,
  "trusted_contact_ids": ["tc_550e8400-e29b-41d4-a716-446655440000"]
}
```
- **Response 201 Created:**
```json
{
  "session_id": "sw_a1290f67-84bc-4180-87a1-cd946b2e0415",
  "status": "ACTIVE",
  "next_checkin_due": "2026-10-11T10:10:00Z",
  "created_at": "2026-10-11T10:00:00Z"
}
```

### POST `/api/v1/safe-walks/{id}/checkin`
- **Description:** Check in safely, resetting the countdown timer.
- **Request Body:**
```json
{
  "latitude": 28.5900,
  "longitude": 77.3400
}
```
- **Response 200 OK:**
```json
{
  "session_id": "sw_a1290f67-84bc-4180-87a1-cd946b2e0415",
  "status": "ACTIVE",
  "next_checkin_due": "2026-10-11T10:20:00Z"
}
```

---

## 7. Community Reports

### GET `/api/v1/community/reports`
- **Description:** Fetch community safety reports within bounding box or user city.
- **Query Params:** `lat`, `lng`, `radius_km`
- **Response 200 OK:** List of fuzzed reports. Exact coords are fuzzed to 2 decimal places (~500m precision).

### POST `/api/v1/community/reports`
- **Description:** Submit a community safety warning or observation.
- **Request Body:**
```json
{
  "category": "POOR_LIGHTING",
  "title": "Broken streetlights along main pedestrian pathway",
  "description": "Entire 400m stretch is completely dark after 8 PM.",
  "latitude": 28.5812,
  "longitude": 77.3190
}
```
- **Response 201 Created**

---

## 8. Real-Time WebSocket `/api/v1/ws`
- Connect: `GET /api/v1/ws?token=<Firebase_Bearer_Token>`
- JSON frame messages:
```json
{
  "action": "subscribe",
  "topic": "incident:inc_71c48201-1b91-49fa-9488-82d2bb95f87b"
}
```
- Server push event:
```json
{
  "event": "status_changed",
  "incident_id": "inc_71c48201-1b91-49fa-9488-82d2bb95f87b",
  "status": "HELPER_ACCEPTED",
  "timestamp": "2026-10-11T10:02:00Z"
}
```
