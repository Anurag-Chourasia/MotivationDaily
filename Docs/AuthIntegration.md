# AuthKit integration — 31 October 2026

AuthKit and AuthKitUI 0.2.3 are linked to the app target. AppAuthGate owns auth
observation at the app root; each bundle has a distinct Keychain session key and
callback scheme. The client-public Supabase URL and publishable key are in Info.plist.
No test account email/password or service-role key is included.

Email/password login and signup are enabled. Account provides local-only sign-out.
Password recovery routes before normal authenticated content. AuthGate rejects
callbacks whose scheme, host or path differs from this app's configured endpoint.

Google and GitHub are enabled in Supabase (verified via the public auth settings API).
AUTH_PROVIDERS is google,github; Apple remains disabled pending developer setup.
The following exact callback URLs are allowlisted in Supabase:

- mytv-auth://auth/callback
- showbook-auth://auth/callback
- motivationdaily-auth://auth/callback

Provider configuration requires a signed-in Supabase dashboard plus OAuth credentials
from Google Cloud, GitHub and Apple Developer. A publishable key cannot change it.

ShowBook binds its existing bookmark email namespace only after cloud authentication;
legacy local credentials are not uploaded or automatically converted into cloud accounts.
MyTV/Motivation Daily favourites remain local device data; account-specific cloud sync
is outside this integration. Production authentication cannot be bypassed. Motivation
Daily's existing Debug-only -UITestMode feature journeys run with offline fixtures.

Validation: all three Debug simulator builds passed using isolated source copies
(byte-identical production sources), exact dependency pins verified. Live AuthKit
sign-in/session/refresh/local-sign-out tests passed. Motivation Daily's Back-button
UI journey passed. ShowBook account-scope/logout unit tests passed.

The apps are installed on iPhone 11 / iOS 27.0 for manual testing. Host integration changes are tracked on the milestone completion branch.
The app dependency record pins AuthKit 0.2.3.

Google/GitHub browser sign-in and email recovery still require end-to-end simulator validation.

Account now offers Reset password with the account email prefilled, plus Sign out.
Forgot password requests a recovery link while signed out. The email link opens the
new-password/confirmation form on the requesting device. Google/GitHub are enabled.

## Developer-first launch and auth rollout — 1 November 2026

Motivation Daily Debug opens Developer settings before AuthKit/session restoration.
Authentication · AuthKit defaults off (developer.authentication). Open Motivation Daily
applies the selected flag. Shake to reopen settings and Apply and close to remount
the app with the changed configuration. Turning it off preserves the cloud session.
Release ignores developer preferences and reads only bundled AUTHKIT_ENABLED,
currently false. Production rollout must deliberately enable that setting.

With AuthKit off, the normal feed opens directly. The existing DEBUG-only UITestMode
offline feature journeys continue to open fixtures without developer launch settings.

Validation: targeted AuthenticationFlagTests passed; signed Debug and Release
simulator builds passed. Manually checked developer-first launch, AuthKit-on
sign-in route and AuthKit-off existing content route on iPhone 11 / iOS 27.0.
Logs: /tmp/motivation-developer-flag-test-retry.log and /tmp/motivation-developer-flag-release.log.
