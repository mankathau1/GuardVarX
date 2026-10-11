# GUARDVARX — Security and Privacy Specification
**Safety. Connected. | The Human Emergency Network**

## 1. Core Security & Privacy Tenets
1. **Zero Unconsented Tracking:** Location tracking is strictly disabled by default. It is active *only* during an active Safe Walk session or an active SOS incident.
2. **Ephemeral Location Retention:** GPS coordinate breadcrumbs have an enforced Time-To-Live (TTL) of 24 hours post-incident resolution. After 24 hours, raw coordinates are permanently purged from database tables, retaining only incident metadata (type, timestamp, resolution state) for user audit history.
3. **No Exact Public Geolocation:** Community safety reports fuzz geographic coordinates to ~500 meters (rounding to 2 decimal places) to prevent pinpointing victim homes, workplaces, or schools.
4. **Defense in Depth:** Platform-backed secure storage on mobile, strict TLS 1.3, parameterized queries, and strict Object-Level Authorization (IDOR protection).

---

## 2. Threat Modeling & Countermeasures

| Threat Vector | Potential Impact | Architectural Countermeasure |
|---|---|---|
| **Stalker / Abusive Contact** | Abuser monitors victim movements via trusted contact feature. | Mutual consent required. Instant one-tap "Revoke All Access" killswitch. Separate notification vs acknowledgement status. Fake PIN option (duress mode) to mask active alert without alerting perpetrator. |
| **Malicious Responder / Impersonator** | Attacker poses as emergency responder or volunteer to locate vulnerable victims. | Tiered verification: responders must complete phone and ID verification. Responders receive approximate radius only until victim SOS is confirmed. Helper assignment audited. Exact victim location revocable at any second. |
| **False Alarms & Denial of Service** | Malicious users flood system with fake emergencies to overwhelm community. | Rate limiting per user/device. Cryptographic proof of origin. Phone-number verified accounts. Flagged accounts barred from relaying alerts. |
| **Eavesdropping on BLE Mesh** | Nearby third parties sniff Bluetooth packets to track victim whereabouts. | Emergency payload signatures prevent tampering. Ephemeral message IDs prevent tracking device MAC addresses. Ingress gateways re-verify with backend. |
| **Insecure Direct Object Reference (IDOR)** | User queries another user's SOS, location, or contact list by tampering with incident ID. | Strict SQL `WHERE user_id = $auth_user_id` or explicit membership in `incident_access_list` checked in middleware. |
| **Database Compromise** | Exposure of location history and contact numbers. | Transparent Data Encryption (TDE), encrypted connection strings, salted hashes for PINs, and automated pruning of raw coordinate trails. |

---

## 3. Authentication & Authorization

### 3.1. Authentication Architecture
- Mobile clients authenticate via Firebase Authentication (supporting Phone SMS OTP and Google Sign-In).
- On each HTTP request, the client transmits `Authorization: Bearer <Firebase_ID_Token>`.
- The Go backend verifies the JWT using the official Firebase Admin SDK / Google Public Keys:
  - Validates `iss` (`https://securetoken.google.com/<PROJECT_ID>`).
  - Validates `aud` (`<PROJECT_ID>`).
  - Checks token expiration (`exp`) and clock skew.
  - Extracts subject UID (`sub`) and maps to internal PostgreSQL `users` table.

### 3.2. Role-Based Access Control (RBAC)
- `STANDARD_USER`: Can trigger SOS, manage own trusted contacts, initiate Safe Walk, post community reports.
- `VERIFIED_RESPONDER`: Can receive proximity alerts, accept emergency missions within geofence, view incident coordinate streams while mission is active.
- `MODERATOR`: Can review flagged community posts, ban abusive users, resolve disputed reports.
- `ADMIN`: Audited access for infrastructure health, system configurations, and legal compliance.

---

## 4. Cryptographic Storage & Key Management
- **Mobile Device Secrets:** API tokens, offline session keys, and Duress PINs are saved using Flutter `flutter_secure_storage`, backed by Android Keystore (`EncryptedSharedPreferences`).
- **Backend Secrets:** Database credentials, Firebase service account keys, and server signing secrets are provided via environment variables (`.env` in local development, secret management in production). No secrets are committed to Git.
- **Mesh Packet Integrity:** Packet payloads include HMAC-SHA256 digests over `(IncidentUUID || Timestamp || Latitude || Longitude || EmergencyType)` to prevent MITM tampering in transit.

---

## 5. Account Deletion & Right to Be Forgotten
- Any user can trigger full account deletion via `DELETE /api/v1/me`.
- Deletion executes a cascading removal:
  1. Devices and FCM tokens unregistered.
  2. Active Safe Walk and SOS sessions terminated.
  3. Trusted contact associations revoked.
  4. Personal profile information (name, phone, email, avatar) wiped.
  5. Incident records anonymized (`sender_id = NULL`, coordinates wiped) to maintain aggregated statistical validity without identifying individuals.

---

## 6. Audit Logging & Compliance
- Critical actions are logged in an immutable `audit_logs` table:
  - Emergency status changes (create, cancel, resolve).
  - Helper mission acceptances and cancellations.
  - Access to victim coordinate history.
  - Moderator decisions and account blocks.
- Audit records store: `actor_id`, `action`, `resource_type`, `resource_id`, `ip_address`, `user_agent`, `timestamp`.
