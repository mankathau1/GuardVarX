# GUARDVARX — Frontend UI Replication Plan
**Exact Visual Reproduction | The Human Emergency Network**

## 1. Goal & Visual Identity
To replicate the exact GuardVarX Home Page design with pixel-level precision:
- **OLED Pure Black Background:** `#000000`, secondary background `#050505`, primary surface `#101010`.
- **Apple Liquid Glass Aesthetics:** Multi-layered `BackdropFilter` (blur 16-20px), subtle translucent borders (`rgba(255,255,255,0.12)`), elevated glass cards (`rgba(255,255,255,0.09)`), and illuminated color glows.
- **Accents:**
  - Primary Blue: `#1683FF`
  - Cyan: `#00D9FF`
  - Emergency Red: `#FF1744`
  - Success Green: `#00F59B`
  - Warning Amber: `#FFAA00`
  - Trusted Contacts Purple: `#A855F7`
  - Typography: Clean sans-serif (Inter via Google Fonts) with crisp white text (`#FFFFFF`) and muted slate (`#A1A1AA`).

---

## 2. Architecture & Modular Component Structure

```text
mobile/lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         # Extended color palette with purple & illuminated borders
│   │   ├── app_spacing.dart        # 8pt grid spacing tokens
│   │   ├── app_typography.dart     # Inter typography scale
│   │   ├── app_theme.dart          # Material 3 theme configuration
│   │   └── glass_card.dart         # Enhanced Liquid Glass container with glows & press feedback
│   ├── widgets/
│   │   └── gradient_icon_box.dart  # Squircle icon container with colored gradient & ambient glow
│   ├── network/
│   ├── storage/
│   ├── native/
│   └── router/
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── home_header.dart
│   │   │       ├── safety_status_card.dart
│   │   │       ├── location_card.dart
│   │   │       ├── central_sos_section.dart
│   │   │       ├── quick_action_card.dart
│   │   │       ├── safe_walk_session_card.dart
│   │   │       └── safety_tip_card.dart
│   │   └── providers/
│   │       └── home_state_provider.dart
│   ├── sos/
│   ├── safe_walk/
│   ├── contacts/
│   ├── history/                    # Emergency history screen
│   ├── nearby/
│   ├── community/
│   ├── notifications/              # Notification center
│   └── profile/
```

---

## 3. Home Screen Component Hierarchy & Data Flow

1. **Edge-to-Edge System Status Bar:**
   - Black background, white icons, `SystemUiOverlayStyle.light`.
2. **Home Header (`HomeHeader`):**
   - Brand text with rich text: `Guard` (white) + `VarX` (primary blue).
   - Subtitle: `Safety. Connected.`
   - Unread notification bell with indicator dot + avatar with blue neon border.
3. **Safety & Connectivity Status Card (`SafetyStatusCard`):**
   - Glass card with green shield icon, truthful location readiness status.
   - Right: Connectivity status (Wi-Fi/Cellular/BLE Mesh) and timestamp.
4. **Current Location Card (`LocationCard`):**
   - Dark blue glass card with subtle map texture background.
   - Location pin, formatted address, city/state, `± 8m accuracy`, update timestamp, navigation chevron.
5. **Central SOS Section (`CentralSosSection`):**
   - 3-column horizontal alignment:
     - Left: `Safe Walk` glass card (`Share your journey`).
     - Center: Large circular SOS control with concentric rings, ambient red glow, 3-second deliberate hold, and siren icon.
     - Right: `Nearby Help` glass card (`Find trusted people around you`).
6. **Quick-Action Responsive Grid (`QuickActionCard`):**
   - 2x2 grid:
     1. Purple: `Trusted Contacts` (Contact count + Chevron).
     2. Amber: `Emergency History` (Incident count + Chevron).
     3. Green: `Community` (Safety updates + Chevron).
     4. Blue: `Report Something` (Help make places safer + Chevron).
7. **Safe Walk Active-Session Card (`SafeWalkSessionCard`):**
   - Wide card with status indicator, live journey progress or `Start` CTA button.
8. **Safety Tip Card (`SafetyTipCard`):**
   - Amber-accented lightbulb card with practical, non-false-security advice.
9. **Floating Liquid Glass Bottom Navigation Bar:**
   - 5 items: `Home`, `Nearby`, `SOS` (red badge), `Community`, `Profile`.
   - Floating pill with blur and illuminated active tabs.

---

## 4. Verification & Validation Steps
1. Unit tests for quick actions, deliberate hold button, and state updates.
2. Widget tests verifying responsive layout on 390x844 logical viewport without pixel overflows.
3. Zero warnings on `flutter analyze`.
4. Passing test suite on `flutter test`.
