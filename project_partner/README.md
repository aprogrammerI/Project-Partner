# Project Partner

A mobile app that uses a Tinder-style swipe mechanism to help people find the
right partner for a goal — study buddies, project partners, co-founders,
collaborators, and freelancers.

---

## Quick start

```bash
flutter pub get
flutter run
```

> **Required files** (not in git — obtain from the team):
> - `lib/firebase_options.dart`
> - `android/app/google-services.json`

### Demo flow

1. Splash → tap **Get started**
2. Register with a real email / password (≥ 6 chars)
3. Fill out the profile (name, age, faculty, bio, looking-for, skills)
4. Save → you land on the **Discover** tab
5. Swipe right to like, left to pass
6. Mutual like → **"It's a match!"** popup + automatic first message in chat
7. Open **Matches** tab to see all your matches
8. Tap a match to open chat and send messages
9. Tap **Profile → Settings** to edit profile or sign out

---

## Architecture

```
lib/
├── main.dart                          # Firebase init + seed + ProviderScope
├── app.dart                           # MaterialApp + _AuthGate (auth-aware root)
├── core/
│   ├── constants.dart                 # Categories, faculties, predefinedSkills, icons, colors
│   ├── theme.dart                     # AppColors + buildAppTheme()
│   └── routes.dart                    # Named route constants
├── models/
│   ├── user_model.dart                # User { uid, email, name, age, rating, lastActiveAt, … }
│   ├── match_model.dart               # Match { id, userIds, lastMessage, lastMessageAt }
│   └── message_model.dart             # Message { id, matchId, senderId, text, createdAt }
├── services/
│   ├── data_service.dart              # DataService contract (abstract)
│   ├── firebase_data_service.dart     # Firebase implementation (Auth, Firestore)
│   ├── seed_service.dart              # Seeds 10 test users on first launch
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
  `currentUserStreamProvider` (Firestore snapshots stream). It swaps between
  `SplashScreen`, `ProfileSetupScreen`, and `HomeShell` based on auth + profile state.
- **Swipe deck**: `flutter_card_swiper`. The deck is keyed by `cardsCount`, so
  we snapshot the candidate list once on first emit instead of rebuilding on
  every stream update (would reset mid-swipe).
- **Streams everywhere**: every list view (candidates, matches, messages) reads
  from a `StreamProvider` so the UI updates the instant data changes.

---

## Screens

| Screen | File | Providers used | Description |
|--------|------|----------------|-------------|
| `SplashScreen` | `auth/screens/splash_screen.dart` | — | Entry point, navigates to Login or Register |
| `LoginScreen` | `auth/screens/login_screen.dart` | `dataServiceProvider` | Email + password login via Firebase Auth |
| `RegisterScreen` | `auth/screens/register_screen.dart` | `dataServiceProvider` | Creates Firebase Auth account + Firestore user doc |
| `ProfileSetupScreen` | `profile/screens/profile_setup_screen.dart` | `dataServiceProvider`, `currentUserStreamProvider` | Forced after register — fills name, age, faculty, bio, skills, looking-for |
| `HomeShell` | `home/home_shell.dart` | `currentUserStreamProvider` | Bottom nav shell — Discover, Matches, Profile tabs |
| `DiscoveryScreen` | `discovery/discovery_screen.dart` | `dataServiceProvider` | Swipe deck powered by `candidates()` algorithm |
| `MatchesListScreen` | `matches/matches_list_screen.dart` | `dataServiceProvider` | Live list of all matches ordered by last message |
| `ChatScreen` | `chat/chat_screen.dart` | `dataServiceProvider` | Real-time messages stream + send message |
| `ProfileScreen` | `profile/screens/profile_view_screen.dart` | `currentUserStreamProvider` | Shows current user profile + link to Settings |
| `ProfileEditScreen` | `profile/screens/profile_edit_screen.dart` | `dataServiceProvider`, `currentUserStreamProvider` | Edit profile fields + save to Firestore |
| `SettingsScreen` | `settings/screens/settings_screen.dart` | `dataServiceProvider` | Sign out, delete account, about |

---

## Discovery Algorithm

`candidates()` in `FirebaseDataService` applies a 3-tier priority sort:

| Priority | Logic |
|----------|-------|
| 1 (highest) | Users who already liked you — shown first for fast matching |
| 2 | Skills match — more shared skills = higher position |
| 3 | Rating — higher rating = higher position |

**Additional rules:**
- Same `lookingFor` category shown first, then other categories below
- Passed users reappear after 5 minutes (set to 10 days before release)
- If someone liked you and you passed them, they reappear immediately

---

## Match Logic

Handled in `likeUser()` in `FirebaseDataService`:

1. Write `likes/{uid}_{targetUid}` to Firestore
2. Give target user +5 rating and reset their `consecutivePasses` to 0
3. Check if `likes/{targetUid}_{uid}` exists (mutual like)
4. If mutual → create `matches/{matchId}` with both user IDs
5. Give both users +10 rating
6. Write an automatic first message (`"You matched! Say hello 👋"`) so the chat is never empty
7. Return the `Match` object → UI shows the match popup

If no mutual like → return `null` (no popup).

---

## Rating System

| Event | Change |
|-------|--------|
| Someone likes you | +5 |
| Consecutive passes (3 in a row) | -1 |
| Mutual match | +10 for both |
| First message sent in a match | +5 |
| Inactive 10+ days | -10 (applied at sort time, not written to DB) |

---

## Firestore Layout

```
users/{uid}
  email, name, age, photoUrl, bio, faculty, skills[],
  lookingFor, createdAt, rating, lastActiveAt, consecutivePasses

likes/{fromUid}_{toUid}
  from, to, createdAt

passes/{fromUid}_{toUid}
  from, to, createdAt

matches/{matchId}
  userIds: [uidA, uidB]
  createdAt, lastMessage, lastMessageAt

matches/{matchId}/messages/{messageId}
  matchId, senderId, text, createdAt
```

---

## Dependencies

| Package               | Why                                            |
|-----------------------|------------------------------------------------|
| `flutter_riverpod`    | App-wide state management                      |
| `flutter_card_swiper` | Swipe deck on the Discover screen              |
| `cached_network_image`| Smooth network image loading                   |
| `image_picker`        | Pick profile photo from gallery / camera       |
| `intl`                | Chat timestamp formatting                      |
| `google_fonts`        | Inter font family                              |
| `firebase_core`       | Firebase initialization                        |
| `firebase_auth`       | Authentication                                 |
| `cloud_firestore`     | Real-time database                             |

