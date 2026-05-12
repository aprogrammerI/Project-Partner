# Project Partner

A mobile app that uses a Tinder-style swipe mechanism to help people find the
right partner for a goal — study buddies, project partners, co-founders,
collaborators, and freelancers.

This repo is the **Person 1 deliverable** (UI + mock backend). Person 2 will
plug in Firebase without touching any UI code.

---

## Status

| Part | Scope                                          | Status   |
|------|------------------------------------------------|----------|
| A    | Foundation (theme, models, mock service)       | Done     |
| B    | Auth + onboarding (splash, login, register, profile setup) | Done     |
| C    | Core experience (discover, swipe, match, chat, matches list) | Done     |
| D    | Polish + handoff (settings, auto-reply, README) | Done     |
| E    | Firebase integration                            | Person 2 |

The app currently runs end-to-end on a mock in-memory backend. Every screen,
state, and transition that Person 2 needs to support is reachable from the UI.

---

## Quick start

```bash
flutter pub get
flutter run
```

Recommended targets while developing the UI:

- **Chrome** — fastest, no emulator, hot-reload in milliseconds.
- **Windows desktop** — `flutter run -d windows` if you prefer a native window.
- **Android emulator** — works, but slower to start.

### Demo flow

1. Splash → tap **Get started**
2. Register with any email / any password (≥ 6 chars)
3. Fill out the profile (photo is optional; pick at least a name, age, faculty,
   bio, looking-for, and one skill)
4. Save → you land on the **Discover** tab
5. Swipe right on **Elena Trajkovska** or **Maja Ilieva** to trigger the
   "It's a match!" popup
6. Tap **Send a message** to open the chat — send a message and watch the other
   user auto-reply ~2 s later (mock only; see `MockDataService._scheduleAutoReply`)
7. Open **Matches** tab — two pre-seeded conversations with **Ana** and **David**
8. Tap **Profile → Settings** to edit profile, sign out, or "delete" the account

---

## Architecture

```
lib/
├── main.dart                          # Runs ProviderScope + ProjectPartnerApp
├── app.dart                           # MaterialApp + _AuthGate (auth-aware root)
├── core/
│   ├── constants.dart                 # Looking-for categories, faculties, icons, colors
│   ├── theme.dart                     # AppColors + buildAppTheme()
│   └── routes.dart                    # Named route constants (declarative push usage)
├── models/
│   ├── user_model.dart                # User { uid, email, name, age, photoUrl, … }
│   ├── match_model.dart               # Match { id, userIds, lastMessage, lastMessageAt }
│   └── message_model.dart             # Message { id, matchId, senderId, text, createdAt }
├── services/
│   ├── data_service.dart              # The DataService contract (auth / profile / discover / match / chat)
│   ├── mock_data_service.dart         # In-memory implementation used by Part 1
│   └── providers.dart                 # dataServiceProvider + currentUserStreamProvider
├── shared/widgets/                    # PrimaryButton, UserAvatar, LookingForChip, EmptyState
└── features/
    ├── auth/screens/                  # splash, login, register
    ├── profile/                       # setup, edit, view + ProfileForm widget
    ├── home/                          # HomeShell (bottom NavigationBar + IndexedStack)
    ├── discovery/                     # DiscoveryScreen + SwipeCard, MatchPopup, UserDetailSheet
    ├── chat/                          # ChatScreen + MessageBubble
    ├── matches/                       # MatchesListScreen
    └── settings/                      # SettingsScreen (edit profile, sign out, delete, about)
```

### Key choices

- **State management**: Riverpod 2 (`flutter_riverpod`). All UI reads data via
  providers, never via concrete implementations.
- **Auth-aware routing**: `_AuthGate` sits at `MaterialApp.home` and watches
  `currentUserStreamProvider`. It swaps between `SplashScreen`,
  `ProfileSetupScreen`, and `HomeShell` based on auth state. Pushed routes
  (Settings, ProfileEdit, Chat) sit on the same Navigator, so destructive
  actions `popUntil((r) => r.isFirst)` after logout.
- **Swipe deck**: `flutter_card_swiper`. The deck is keyed by `cardsCount`, so
  we snapshot the candidate list once on first emit instead of rebuilding on
  every stream update (would reset mid-swipe).
- **Streams everywhere**: every list view (candidates, matches, messages) reads
  from a `StreamProvider` so the UI updates the instant data changes — same
  shape Firestore snapshots will have.

---

## For Person 2 — Firebase integration

This is your TODO list. **You do not need to touch any screen** to integrate
Firebase. Every screen depends on the `DataService` abstraction.

### The one file you'll swap

[`lib/services/providers.dart`](lib/services/providers.dart)

```dart
final dataServiceProvider = Provider<DataService>((ref) {
  return MockDataService();          // ← swap to FirebaseDataService();
});
```

### What you need to build

Create `lib/services/firebase_data_service.dart` that implements
[`DataService`](lib/services/data_service.dart). The interface is:

| Method                                   | Where to point it                                    |
|------------------------------------------|------------------------------------------------------|
| `currentUser()`                          | Firebase Auth + Firestore `users/{uid}` lookup       |
| `currentUserChanges()`                   | `FirebaseAuth.authStateChanges().asyncMap(...)`      |
| `register({email, password})`            | `createUserWithEmailAndPassword` + create user doc with empty profile |
| `login({email, password})`               | `signInWithEmailAndPassword` + read user doc         |
| `logout()`                               | `signOut()`                                          |
| `updateProfile(user)`                    | `users/{uid}.set(user.toJson(), merge: true)`        |
| `uploadProfilePhoto(file)`               | Upload to `profile_photos/{uid}.jpg` → return download URL |
| `getUserById(uid)`                       | `users/{uid}.get()`                                  |
| `candidates()`                           | Stream of `users` collection, filter out current user and anyone in `matches`/`swipes/{uid}` |
| `likeUser(targetUid)`                    | Write `likes/{uid}_{targetUid}`. If `likes/{targetUid}_{uid}` exists → create `matches/{...}` and return it |
| `passUser(targetUid)`                    | Write `passes/{uid}_{targetUid}` (or single `swipes` collection with direction)        |
| `matches()`                              | Stream of `matches` where `userIds` array-contains current uid, ordered by `lastMessageAt` desc |
| `messages(matchId)`                      | Stream of `matches/{matchId}/messages` ordered by `createdAt` asc |
| `sendMessage({matchId, text})`           | Add to `matches/{matchId}/messages` and update parent's `lastMessage` + `lastMessageAt` |

All models already have `fromJson` / `toJson`, so reads and writes are one-liners.

### Recommended Firestore layout

```
users/{uid}
  email, name, age, photoUrl, bio, faculty, skills[], lookingFor, createdAt

likes/{fromUid}_{toUid}
  from, to, createdAt

passes/{fromUid}_{toUid}
  from, to, createdAt

matches/{matchId}
  userIds: [uidA, uidB]
  createdAt
  lastMessage
  lastMessageAt

matches/{matchId}/messages/{messageId}
  matchId, senderId, text, createdAt
```

### Things you can delete after the swap

- [`lib/services/mock_data_service.dart`](lib/services/mock_data_service.dart)
- The `_scheduleAutoReply` helper inside it (canned chat replies — demo only)
- The `_willMatchBack` set + the seeded "match-back" candidates

### Things to keep an eye on

- **Match popup**: the UI shows the match popup whenever `likeUser` returns a
  non-null `Match`. With Firestore, the second side of a mutual like usually
  arrives via a server-side function or a transaction — make sure
  `likeUser` returns the freshly created match doc.
- **Stream replay**: the mock service emits the current snapshot on first
  subscribe via `async*` + `yield`. Firestore does this natively — no work
  needed.
- **Photo upload**: `uploadProfilePhoto` currently returns the local file path,
  which `UserAvatar` recognizes and renders via `Image.file`. Once it returns a
  real `https://…` URL from Firebase Storage, `UserAvatar` uses
  `CachedNetworkImage` automatically. No widget changes needed.

---

## Dependencies

| Package              | Why                                                    |
|----------------------|--------------------------------------------------------|
| `flutter_riverpod`   | App-wide state management                              |
| `flutter_card_swiper`| Swipe deck on the Discover screen                      |
| `cached_network_image`| Smooth network image loading for avatars and cards    |
| `image_picker`       | Pick profile photo from gallery / camera               |
| `intl`               | Chat timestamp formatting                              |
| `google_fonts`       | Inter font family                                      |
| `uuid`               | IDs for mock data                                      |

Person 2 will additionally add: `firebase_core`, `firebase_auth`,
`cloud_firestore`, `firebase_storage`.

---

## Suggested git workflow

- `main`   — stable, demo-ready
- `dev`    — integration branch
- `part-1-ui-done` — snapshot of the UI-only milestone before Firebase work
- `firebase-integration` — Person 2's feature branch off `dev`
