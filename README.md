# A-Mail by Adverune

**Your Email. Your Identity.**

A-Mail is Adverune's independent email app: a native Flutter client for `@adverune.store` mailboxes, with a Gmail-familiar workflow and an original Adverune design.

> **Status: Phase 1 (mobile app).** The app is complete as a client and backend-ready. The A-Mail backend (Phase 2) does not exist yet, so the app shows honest "server not connected" states. It never fabricates emails.

## What works today
- Splash, onboarding, welcome, register, login, forgot password, email verification, OTP, recovery, biometric app lock
- Inbox with avatars, unread dots, stars, importance, attachment markers, conversation counts, label chips, filters, pull-to-refresh, pagination, swipe archive/delete (configurable), multi-select and bulk actions
- Conversation view, reply, reply all, forward, star, mark unread, archive, delete, spam, snooze, share, attachments
- Compose with To/Cc/Bcc + contact suggestions, rich text (bold, italic, underline, lists, links), attachments, image insertion, draft autosave, schedule send, undo send
- Folders: Inbox, Starred, Snoozed, Sent, Drafts, Scheduled, Important, All Mail, Spam, Trash
- Search + advanced search, labels (create/rename/recolour/delete/assign), contacts (create/edit/delete/quick compose)
- Notifications (history, preferences, device registration architecture), settings (profile, security, 2FA, devices, signature, appearance, storage, account), storage manager, premium plans UI (display only)
- Light and dark themes (Material 3), offline cache, queued offline actions

## Needs the backend (Phase 2)
Registration, login, username availability, real mail send/receive, push delivery, subscriptions/payments, 2FA enrolment, device/login history. These call the REST contract in [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) and fail with a clear message until a server is configured.

## Configure the API
Default: `https://api.adverune.store` (the A-Mail backend must be deployed there). Override at build time:
```
flutter run --dart-define=A_MAIL_API_URL=https://your-host
```
or in the app under **Settings > Account > API server address**.

## Develop
```
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
Android: minSdk 23, compileSdk 36, core library desugaring enabled. Release builds use the debug key until a real keystore is provided through CI secrets. No signing keys are stored in this repo.

## Structure
`lib/core` (config, constants, theme, network, security, services) · `lib/models` · `lib/data` · `lib/providers` · `lib/navigation` · `lib/screens` · `lib/shared`.
