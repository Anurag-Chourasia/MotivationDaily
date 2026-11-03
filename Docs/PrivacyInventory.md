# Motivation Daily Privacy Inventory & Manifest Declarations

Last updated: 3 November 2026

## 1. Overview & Data Philosophy
Motivation Daily is an inspirational quote and aesthetic wallpaper application built with a strict privacy-first architecture:

- **Zero Tracking**: Motivation Daily does not track users across third-party websites or applications (`NSPrivacyTracking: false`).
- **No Third-Party Ad Networks or Telemetry Brokers**: No advertising identifiers (IDFA), tracking SDKs, or commercial behavioral analytics are bundled.
- **Offline & Local by Default**: Favorited quotes and presentation preferences are stored strictly on-device in `UserDefaults`. Quote and wallpaper image caches are local and purgeable at any time.

---

## 2. Collected Data Categories (Apple Privacy Nutrition Label)

| Data Type | Purpose | Linked to User? | Used for Tracking? | Retention / Storage |
| :--- | :--- | :--- | :--- | :--- |
| **User ID** (`NSPrivacyCollectedDataTypeUserID`) | App Functionality (Cloud account identification when AuthKit is enabled) | Yes | No | Retained in Keychain until sign-out or account deletion. |
| **Email Address** (`NSPrivacyCollectedDataTypeEmailAddress`) | App Functionality (User login, verification, and password recovery) | Yes | No | Retained in Supabase Auth until account deletion. |
| **Other User Content** (`NSPrivacyCollectedDataTypeOtherUserContent`) | App Functionality (User favorited quotes) | Yes | No | Stored locally on-device in `UserDefaults` (`favoriteQuotes`). |

---

## 3. Required-Reason APIs (`PrivacyInfo.xcprivacy`)

In accordance with Apple App Store review guidelines, Motivation Daily declares all required-reason APIs accessed by the application:

### `NSPrivacyAccessedAPICategoryUserDefaults`
- **Reason Code**: `CA92.1`
- **Declared Usage**: Accessing `UserDefaults` and `@AppStorage` solely to read and write app preferences, favorite quotes, user settings, and developer showcase flags on device.

---

## 4. Network Endpoints & Third-Party SDKs

1. **Quote & Wallpaper Providers** (`Quotable`, `ZenQuotes`, `AdviceSlip`, `Picsum`):
   - Public read-only quote and image APIs.
   - Unauthenticated GET requests with standard user agent; no user identity or PII transmitted.
2. **Supabase Auth** (`AuthKit`):
   - Client authentication with public publishable keys over TLS 1.3.

---

## 5. Storage & Sensitive Credential Logging Policy

- **Keychain**: Supabase session tokens are stored in Keychain when authenticated.
- **Cache**: Ephemeral quotes and wallpapers stored in `.cachesDirectory` and purgeable at any time.
- **Logging Audit**: Logging audit verified that passwords, tokens, quotes, and user credentials are never logged to console or standard output.

---

## 6. Support & Privacy Contact
- **Privacy Policy**: [https://github.com/Anurag-Chourasia/Motivation-Daily/blob/main/Docs/PrivacyInventory.md](https://github.com/Anurag-Chourasia/Motivation-Daily/blob/main/Docs/PrivacyInventory.md)
- **Developer Support**: [mailto:anuragchourasiaios@gmail.com](mailto:anuragchourasiaios@gmail.com)
