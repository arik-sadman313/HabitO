# HabitO — Complete Project Handoff & Continuation Report

**Document purpose:** Permanent handoff document for continuing HabitO across ChatGPT/Gemini/Antigravity accounts.

**Current project state:** Phases 1–18 completed and verified. Phase 18 (Screen Time Synchronization) has been fully verified across Flutter, FastAPI backend, SQLAlchemy/Alembic migrations, JWT security, and automated unit test suites.

**Critical rule:** Do not start Phase 19 automatically. Stop and wait for instructions after completing any phase.

---

# 1. Project Overview

## Project Name

**HabitO**

HabitO is a private, offline-first personal life-management and couple/life-tracking application for two consenting users.

The long-term vision is to track a user's life in one place:

- Daily routine
- Activities
- Habits
- Habit completion
- Generic trackers
- Study
- Food/meals
- Water
- Sleep
- Exercise
- Journal
- Mood/wellbeing
- Personal goals
- Progress and analytics
- Screen time
- Reminders
- Shared/couple goals
- Shared habits
- Shared activities
- Memories
- Shared journal entries
- Eventually synchronized couple data

The app is intended to be a real production-quality application, not a disposable prototype.

The architecture is deliberately **local-first / offline-first**.

---

# 2. Core Product Principles

These principles must be preserved throughout future development.

## 2.1 Local-first

The local Drift/SQLite database is the application's UI source of truth.

The user must be able to use the app offline.

Remote synchronization happens around the local database rather than replacing it.

## 2.2 Real data only

Never fabricate:

- partner statistics
- screen-time values
- analytics
- completion rates
- moods
- study time
- health/lifestyle values
- synchronization results

If data is unavailable, show an explicit unavailable/partial state.

Do not silently convert "unknown" into zero.

## 2.3 Personal vs shared data

Personal records are generally keyed by:

`userId`

Couple/shared records are generally keyed by:

`coupleId`

However:

> Couple membership does NOT automatically grant access to every personal record.

A personal journal entry marked as `shared` must not automatically become visible to the other couple member through ordinary personal synchronization.

Explicit couple-scoped synchronization/access will be implemented separately later.

## 2.4 Repository architecture

Do not create:

`Widget -> Dio/API`

Instead:

`UI -> Riverpod -> Repository -> Local DB / Sync Engine -> Backend`

Existing repositories and domain models should be reused.

Do not create parallel duplicate repositories for the same entity.

## 2.5 Derived analytics

Analytics should generally be calculated from source records.

Do not blindly synchronize derived values such as:

- current streak
- completion percentage
- mood averages
- historical trends
- goal progress
- analytics summaries

Source data should synchronize; derived analytics should be recalculated locally.

## 2.6 Synchronization

Current synchronization model:

- local mutation first
- enqueue synchronization operation in the same local transaction
- push queued mutations
- pull remote changes using a cursor
- apply remote changes locally
- remote application must NOT re-enter SyncQueue
- server is authoritative for conflicts
- last-write-wins
- soft deletion/tombstones must be preserved
- no CRDT
- no intelligent text merge unless explicitly designed later

## 2.7 Security

Authentication uses JWT.

The server must derive ownership from the authenticated JWT rather than trusting arbitrary `userId` values in payloads.

Never log:

- passwords
- JWTs
- refresh tokens
- journal body/title unnecessarily
- mood values unnecessarily
- sensitive personal records unnecessarily

---

# 3. Technology Stack

## Flutter

- Flutter stable: 3.47.4
- Dart: 3.13.3
- Android target currently tested on Android device
- Riverpod
- Riverpod code generation
- Drift
- SQLite
- Dio
- GoRouter
- flutter_secure_storage
- flutter_local_notifications
- flutter_timezone
- shared_preferences
- logger
- flutter_dotenv

## Backend

- FastAPI
- Python
- SQLAlchemy 2.0 async
- PostgreSQL
- Alembic
- Pydantic
- Docker Compose
- JWT authentication

## Development Environment

Primary development environment:

- Fedora Linux 43 KDE
- Java 21
- Git/GitHub
- Android SDK
- Flutter stable

---

# 4. High-Level Architecture

```text
                   ┌───────────────────────┐
                   │       Flutter UI      │
                   └───────────┬───────────┘
                               │
                         Riverpod State
                               │
                   ┌───────────▼───────────┐
                   │      Repositories     │
                   └───────┬─────────┬─────┘
                           │         │
                    Local DB       Sync
                           │         │
                   ┌───────▼───┐ ┌──▼───────────┐
                   │ Drift /   │ │ Sync Engine  │
                   │ SQLite    │ │ + Dio        │
                   └───────────┘ └──────┬────────┘
                                        │
                                  HTTPS / JWT
                                        │
                              ┌─────────▼─────────┐
                              │ FastAPI Backend   │
                              ├───────────────────┤
                              │ Auth              │
                              │ Sync              │
                              │ Ownership         │
                              │ Conflict handling │
                              └─────────┬─────────┘
                                        │
                              ┌─────────▼─────────┐
                              │ PostgreSQL        │
                              └───────────────────┘
```

GitHub stores source code, CI/release artifacts, and development history.

GitHub is NOT the live-data synchronization backend.

---

# 5. Flutter Navigation

The bottom navigation must remain exactly:

1. Home
2. Today
3. Track
4. Us
5. Journal

Do NOT move Study or Lifestyle into the bottom navigation.

Top-level routes include things such as:

- `/study`
- `/study/timer`
- `/lifestyle/food`
- `/lifestyle/water`
- `/lifestyle/sleep`
- `/lifestyle/exercise`
- `/screen-time`
- `/wellbeing`
- `/wellbeing/check-in`
- `/reminders`
- `/reminders/new`

Avoid turning the bottom navigation into an overcrowded feature menu.

---

# 6. Database Schema History

The local Drift schema has progressed through multiple versions.

## Schema v1 — Foundation

Core tables:

- UsersTable
- CouplesTable
- TrackersTable
- TrackerLogsTable
- HabitsTable
- HabitLogsTable
- ActivitiesTable

Common synchronization-related fields include:

- `syncStatus`
- `updatedAt`
- `isDeleted`

Domain models remain separate from generated Drift row types.

---

## Schema v2 — Study

Added:

- StudySubjectsTable
- StudySessionsTable

Study timer uses timestamp-based calculations.

---

## Schema v3 — Lifestyle

Added:

- MealsTable
- MealItemsTable
- SleepRecordsTable
- ExerciseSessionsTable

Water uses the existing generic tracker system.

Important sleep rule:

> A sleep record logically belongs to the wake-up day, with timezone-aware handling.

---

## Schema v4 — Journal + Wellbeing

Added:

- JournalEntriesTable
- MoodLogsTable

Journal entry fields include concepts such as:

- userId
- title
- body
- journalType
- tags

Journal types include:

- personal
- shared

Mood logs include:

- daily mood
- energy
- stress

using a 1–5 scale.

---

## Schema v5 — Couple / Us

Added:

- SharedGoalsTable
- SharedHabitsTable
- SharedActivitiesTable
- MemoriesTable

Shared records use `coupleId`.

---

## Schema v6 — Screen Time

Added:

- ScreenTimeDailySnapshotsTable

Android Usage Access API is used for real device screen-time data.

---

## Schema v7 — Personal Goals

Added personal goal storage.

Personal goals remain separate from shared goals.

Goal progress is derived from source records through GoalProgressService.

---

## Schema v8 — Reminders

Added:

- ReminderSchedulesTable

Reminder schedules are the source of truth for local notifications.

---

## Schema v9 — Offline Sync

Added:

- SyncQueueTable

Used for local-first synchronization.

Important synchronization state includes concepts such as:

- pending mutations
- stable device ID
- last server cursor
- retry handling

Do not bump the Flutter schema version unless a genuine local schema change is required.

---

# 7. Completed Phases

## Phase 1 — Flutter Foundation

Completed.

Implemented:

- Flutter project
- feature-first folders
- `core/`
- `features/`
- `shared/`
- Riverpod
- GoRouter
- Material 3
- light/dark themes
- Dio foundation
- dotenv foundation
- Logger
- Riverpod code generation

---

## Phase 2 — Database

Completed.

Implemented:

- Drift
- SQLite
- schema v1
- domain models separate from generated rows
- UserRepository
- TrackerRepository
- sync metadata fields
- generic tracker logs
- database tests

---

## Phase 3 — Authentication

Completed.

Implemented:

- AuthState
- AuthNotifier
- SecureSessionManager
- JWT access/refresh token storage
- MockAuthRepositoryImpl
- login
- registration
- onboarding/couple pairing UI
- GoRouter auth guards
- session restoration
- authentication tests

Mock authentication remains available for development until replaced/disabled appropriately.

---

## Phase 4 — Home + Today

Completed.

Implemented:

- StatefulShellRoute
- bottom navigation
- ActivityRepository
- activity CRUD
- activity completion
- soft delete
- reactive Drift streams
- Home
- Today
- date navigation
- ActivityFormScreen
- progress cards
- timeline
- tests

---

## Phase 5 — Generic Tracking + Habits

Completed.

Implemented:

- TrackerValue hierarchy
- BooleanValue
- DecimalValue
- DurationValue
- TrackerValueConverter
- TrackerRepository
- HabitRepository
- StreakCalculator
- Track screen
- quick actions
- habit dashboard
- streak calculations
- completion rate

---

## Phase 6 — Study

Completed.

Implemented:

- StudySubject
- StudySession
- schema v2
- timestamp-based study timer
- pause/resume
- Study dashboard
- Study timer
- Home study overview
- Today study section
- tests

Important:

Study remains a top-level feature and is NOT a bottom-navigation tab.

---

## Phase 7 — Lifestyle

Completed.

Implemented:

- Food
- Meals
- Meal items
- Water
- Sleep
- Exercise
- schema v3
- repositories
- lifestyle routes
- Home integration
- Today integration
- timezone-aware sleep logical-day handling

---

## Phase 8 — Journal + Mood/Wellbeing

Completed.

Implemented:

- schema v4
- JournalEntriesTable
- MoodLogsTable
- JournalEntry model
- MoodLog model
- JournalRepository
- MoodRepository
- Journal screen
- personal/shared filters
- SQLite search
- new journal
- journal detail
- Wellbeing screen
- mood check-in
- Home wellbeing
- Today wellbeing
- Today journal

Important distinction:

`My Journal` and `Our Journal` are structurally distinct.

Mutual consent does not remove this architectural distinction.

---

## Phase 9 — Couple / Us

Completed.

Implemented:

- schema v5
- SharedGoal
- SharedHabit
- SharedActivity
- Memory
- UsRepository
- currentCoupleProvider
- partnerProvider
- shared goals provider
- memories provider
- `/us`
- partner header
- today together placeholder
- shared goals
- memories timeline
- Our Journal
- Home Together summary
- Today Together section

No fabricated partner data.

---

## Phase 10 — Real Android Screen Time

Completed and verified.

Implemented:

Android:

- `PACKAGE_USAGE_STATS`
- MethodChannel:
  `com.habito.habito/screen_time`
- usage access checking
- usage access settings
- UsageStatsManager
- PackageManager app names

Flutter:

- ScreenTimeSummary
- AppUsage
- ScreenTimeDay
- ScreenTimeAccessState
- ScreenTimeRepository
- providers
- app-resume refresh
- schema v6
- screen-time UI
- Home summary
- Today summary
- weekly trend

Permission states are distinct from genuine zero usage.

Verification included:

- Flutter tests
- analyze
- release APK
- manual Android permission and data verification

---

## Phase 11 — Personal Goals + Analytics

Completed and verified.

Implemented:

- personal goals
- PersonalGoalsTable
- GoalProgressService
- analytics dashboard
- Sleep historical data
- Food historical data
- Mood historical data
- Study historical data
- Exercise historical data
- Home goal integration
- Today goal integration

Analytics supports:

- 7-day
- 30-day
- 90-day

Data availability distinguishes:

- available
- partial
- unavailable

No fake zeros.

No mental-health diagnosis.

Analytics are calculated locally from source data.

---

## Phase 12 — Local Notifications + Smart Reminders

Completed and verified.

Implemented:

- flutter_local_notifications
- flutter_timezone
- schema v8
- ReminderSchedulesTable
- NotificationService
- NotificationScheduler
- notification channels
- reminders UI
- reminder creation
- Today upcoming reminders
- notification settings
- startup payload handling
- deep linking
- boot receiver
- notification permission flow
- recurring scheduling
- cancellation/rescheduling

Deep links were explicitly verified for Study and Goal reminder types.

Potential future improvement:

Add/complete deep links for other reminder types where useful.

---

## Phase 13 — Backend Foundation + Offline Sync Engine

Completed.

Backend:

- FastAPI
- SQLAlchemy 2.0 async
- PostgreSQL
- Docker Compose
- Alembic
- User model
- Couple model
- SyncChange model
- authentication endpoints
- sync endpoints
- JWT

Flutter:

- DioClient
- shared preferences
- token refresh interceptor
- AppConfig.useMockAuth
- schema v9
- SyncQueueTable
- SyncEngine
- stable local device ID
- lastServerCursor
- manual Sync Now

Backend tests passed.

Flutter tests reached 27 tests.

APK build successful.

---

## Phase 14 — Core Personal Data Synchronization

Completed.

Synchronized:

- Habits
- Habit Logs
- Trackers
- Tracker Logs
- Activities

Backend:

- SQLAlchemy models
- Pydantic DTOs
- PostgreSQL tables
- `/api/v1/sync/push`
- `/api/v1/sync/pull`
- ownership validation
- sync routing

Flutter:

- repository local mutations + SyncQueue in same transaction
- DTO serialization/deserialization
- remote apply methods
- dependency ordering
- transaction rollback
- loop prevention
- retry safeguards

Conflict model:

- server-authoritative
- last-write-wins

Security principle:

User A must never access User B's personal records.

---

## Phase 15 — Study + Lifestyle Synchronization

Completed.

Synchronized:

- StudySubject
- StudySession
- Meals
- MealItems
- SleepRecords
- ExerciseSessions

Water continues using:

- Tracker
- TrackerLog

No duplicate Water synchronization system should be created.

Flutter repositories queue:

- save
- archive
- delete

and can apply remote changes.

SyncEngine dependency order was extended.

Backend:

- models
- migrations
- DTOs
- push/pull routing
- dependency ordering

Verification:

- Flutter tests passed
- analyze clean
- backend push/pull suite extended
- APK built

Important caveat:

At the end of Phase 15, these were still NOT synchronized:

- Journal
- Mood
- Personal Goals
- Screen Time
- Reminders
- Couple/shared data

Therefore do not describe Phase 15 as synchronizing literally every application feature.

---

# 8. Current Synchronization Matrix

| Feature | Local | Backend | Personal Sync | Couple Sync |
|---|---:|---:|---:|---:|
| Habits | Yes | Yes | Yes | No |
| Habit Logs | Yes | Yes | Yes | No |
| Trackers | Yes | Yes | Yes | No |
| Tracker Logs | Yes | Yes | Yes | No |
| Activities | Yes | Yes | Yes | No |
| Study Subjects | Yes | Yes | Yes | No |
| Study Sessions | Yes | Yes | Yes | No |
| Meals | Yes | Yes | Yes | No |
| Meal Items | Yes | Yes | Yes | No |
| Sleep | Yes | Yes | Yes | No |
| Exercise | Yes | Yes | Yes | No |
| Water | Yes | Yes through Trackers | Yes | No |
| Journal | Yes | Yes (`journal_entries`) | Synced (Phase 16) | Reserved |
| Mood | Yes | Yes (`mood_logs`) | Synced (Phase 16) | Reserved |
| Personal Goals | Yes | Yes (`personal_goals`) | Synced (Phase 17) | No |
| Screen Time | Yes | Yes (`screen_time_daily_snapshots`) | Synced (Phase 18) | No |
| Reminders | Yes | No/Not yet | No | No |
| Shared Goals | Yes | No/Not yet | No | Future |
| Shared Habits | Yes | No/Not yet | No | Future |
| Shared Activities | Yes | No/Not yet | No | Future |
| Memories | Yes | No/Not yet | No | Future |

---

# 9. Backend API Direction

The API uses versioned routes under:

`/api/v1/`

Important endpoints:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `GET /api/v1/auth/me`
- `POST /api/v1/sync/push`
- `GET/POST /api/v1/sync/pull` depending on current implementation

Before modifying endpoint shapes, inspect the actual backend code.

Do not assume an endpoint method or DTO structure solely from this report.

The actual repository is the source of truth.

---

# 10. Sync Model

## Push

Conceptually:

```text
Local mutation
    ↓
DB transaction
    ├── modify entity
    └── enqueue SyncQueue operation
             ↓
        SyncEngine
             ↓
        POST /sync/push
             ↓
        server validates JWT ownership
             ↓
        server applies LWW
             ↓
        SyncChange recorded
```

## Pull

```text
SyncEngine
    ↓
pull using lastServerCursor
    ↓
server returns changes after cursor
    ↓
apply remote change locally
    ↓
DO NOT enqueue SyncQueue
    ↓
advance cursor
```

## Loop prevention

Remote changes must not create another outbound sync mutation.

This is critical.

---

# 11. Conflict Policy

Current policy:

**Server-authoritative Last-Write-Wins**

Do not introduce:

- CRDT
- merge algorithms
- automatic journal text merging
- client-authoritative conflicts

unless explicitly planned as a future architectural change.

For journal text, Phase 16 specifically uses server-authoritative LWW.

---

# 12. Ownership Rules

The backend must determine the authenticated user from JWT.

Do not trust:

```json
{
  "userId": "some-arbitrary-user"
}
```

as authorization.

The server should validate:

```text
JWT user
    ↓
authenticated identity
    ↓
record ownership
```

A client must not be able to change another user's personal record by modifying a payload `userId`.

---

# 13. Couple / Shared Data Security Rule

This is extremely important.

Suppose:

- User A
- User B
- They belong to the same couple

That does NOT mean User B can automatically receive all records of User A.

In particular:

```text
JournalEntry.userId = User A
JournalEntry.journalType = shared
```

must NOT automatically cause the entry to be returned to User B through ordinary personal synchronization.

Phase 16 personal synchronization should remain user-scoped.

Later, an explicit couple-scoped sync system can be designed for:

- shared goals
- shared habits
- shared activities
- memories
- shared journal
- etc.

---

# 14. Current Phase — Phase 18

## Status

**PHASE 18 IS COMPLETED AND VERIFIED.**

Phase 18 (Screen Time Synchronization) has been fully implemented and verified across Flutter repositories, SyncEngine, DTOs, FastAPI backend sync routes, SQLAlchemy models, Alembic migrations, security/ownership controls, stable daily snapshot identity, and automated unit test suites.

### Verified State Summary:
1. **Database Migration**: `d2e345678901_add_screen_time_sync.py` creates `screen_time_daily_snapshots` PostgreSQL table and index.
2. **Backend Models & DTOs**: `ScreenTimeDailySnapshot` SQLAlchemy model and `ScreenTimeDailySnapshotDto` Pydantic schema implemented.
3. **Backend Sync Routing**: Registered `"screen_time_daily_snapshot": (ScreenTimeDailySnapshot, ScreenTimeDailySnapshotDto)` in `ENTITY_MODELS` routing.
4. **Security & Ownership**: Derive owner from JWT. User A cannot push, pull, modify, or delete User B's screen time snapshots. Payload `user_id` mismatch raises 403 Forbidden.
5. **Stable Identity & Data Minimization**:
   - Synchronizes ONLY daily aggregate snapshots (`date`, `totalDurationSeconds`, `appCount`).
   - Transient per-app package telemetry (`AppUsage`) is NOT synchronized to preserve privacy.
   - Stable ID generated for `(userId, local logical date)` via `Uuid.v5` to prevent duplicate daily snapshot creation upon repeated UsageStats refreshes.
6. **Flutter Synchronization**:
   - `ScreenTimeRepositoryImpl.syncTodaySnapshot`: Local upsert + `SyncQueueTable` insertion executed atomically inside a database transaction (`_db.transaction`).
   - `SyncEngine`: Extended with `orderMap['screen_time_daily_snapshot'] = 1` and remote apply calls.
   - Remote apply methods (`applyRemoteScreenTimeSnapshotChange`, `applyRemoteScreenTimeSnapshotDelete`) update SQLite without re-enqueuing into `SyncQueueTable` (loop prevention).
7. **Test Verification**:
   - Flutter tests: 53 / 53 passed (including 6 Phase 18 screen time sync tests in `test/features/screen_time_sync_test.dart`).
   - Backend tests: 19 / 19 passed (including 3 Phase 18 security/sync tests in `test_sync_phase18.py`).
   - Flutter static analysis: Clean (0 errors).
   - Release APK build: `build/app/outputs/flutter-apk/app-release.apk` built successfully.

---

# 15. Phase 16 Objective

Synchronize:

- JournalEntry
- MoodLog

Do NOT synchronize in Phase 16:

- Journal search indexes
- analytics
- mood averages/trends as derived values
- personal goal progress
- screen time
- reminders
- couple data

---

# 16. Phase 16 Backend Requirements

Inspect existing:

- JournalEntriesTable
- MoodLogsTable

Create backend PostgreSQL models if missing:

- `journal_entries`
- `mood_logs`

Create Alembic migration if missing.

Create DTOs if missing:

- JournalEntryDto
- MoodLogDto

Ownership:

- derive owner from JWT
- do not trust payload ownership fields
- validate every record

Security tests must include:

### Test 1

User A cannot modify User B's journal entry.

### Test 2

User A cannot pull User B's journal entries.

### Test 3

User A cannot modify User B's mood log.

### Test 4

User A cannot pull User B's mood logs.

### Test 5

A shared journal entry owned by User A must NOT be delivered to User B through personal sync.

---

# 17. Phase 16 Flutter Requirements

Integrate:

- JournalRepository
- MoodRepository

Every local mutation should atomically:

```text
database mutation
+
SyncQueue insertion
```

Implement remote application methods such as:

- `applyRemoteJournalChange`
- `applyRemoteMoodChange`

Use existing repository patterns.

Do not create a separate parallel synchronization architecture.

---

# 18. Mood Logical-Day Rule

Mood is a daily record.

Preserve the application's existing timezone/logical-day behavior.

Do not accidentally convert a local daily mood record into a UTC date that changes the user's intended day.

Inspect existing MoodRepository/domain logic before modifying it.

---

# 19. Journal Synchronization

Journal entries should use:

- user ownership
- journal type
- title
- body
- tags
- timestamps
- soft deletion/tombstone behavior

Do not introduce intelligent merge behavior.

If the same journal entry changes on multiple devices:

> Server-authoritative LWW.

Local journal search must continue to work after synchronization.

Do not synchronize a separate search index.

---

# 20. Wellbeing Analytics After Phase 16

MoodLogs are source data.

Once synchronized MoodLogs arrive locally:

Existing Wellbeing Analytics should automatically recalculate from the local source data.

Do NOT synchronize:

- mood averages
- trends
- charts
- derived wellbeing metrics

unless a future phase explicitly requires it.

---

# 21. Sensitive Logging

Do not add logs containing:

- journal title
- journal body
- mood values
- energy values
- stress values
- JWT
- access token
- refresh token
- password

Debug logs should use safe identifiers where necessary.

For example, a record ID is preferable to printing an entire journal entry.

---

# 22. Phase 16 Verification

Backend:

- migration succeeds
- backend tests pass
- ownership tests pass
- shared journal isolation test passes
- push/pull tests pass

Flutter:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk
```

All must pass.

---

# 23. Two-Device Verification

If possible, verify using two devices/emulators representing the same user account.

### Device A

1. Create journal entry
2. Create mood log
3. Sync

### Device B

1. Sync
2. Confirm journal appears
3. Confirm mood appears
4. Edit journal
5. Sync

### Device A

1. Sync
2. Confirm edited journal arrives
3. Confirm wellbeing analytics use synchronized mood data

---

# 24. Different-User Isolation Test

Create:

- User A
- User B

User A:

- creates journal
- creates mood
- syncs

User B:

- syncs

User B must NOT receive User A's personal records.

This remains true even if both users belong to the same couple.

---

# 25. Offline Test

At minimum:

1. Disable network
2. Create/edit journal
3. Create/edit mood
4. Confirm local UI updates immediately
5. Confirm records enter pending sync state
6. Restore network
7. Run Sync Now
8. Confirm server synchronization
9. Confirm another device can receive the records

---

# 26. Git Milestone

Only after the phase is genuinely complete:

Commit:

```text
feat(sync): synchronize journal and wellbeing data
```

Tag:

```text
phase-16-journal-wellbeing-sync
```

Do not create the tag before tests/build/manual verification pass.

---

# 27. Quality Gates

Before declaring any phase complete:

### Backend

- migration check
- tests
- ownership/security tests
- API push/pull tests

### Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk
```

No unresolved analyzer errors.

No knowingly broken tests.

No fake data.

No destructive database reset.

No unnecessary schema changes.

---

# 28. Important Development Rules

## Rule 1 — Inspect before changing

Before making changes, inspect:

- current git status
- recent commits
- existing migrations
- schema version
- relevant repository code
- existing DTOs
- existing SyncEngine
- backend sync routing
- current tests

The repository is the source of truth.

## Rule 2 — Do not rewrite completed architecture

Reuse existing patterns.

Do not rewrite:

- SyncEngine
- DioClient
- authentication
- Drift architecture
- repository pattern
- navigation
- existing feature implementations

unless the current code genuinely requires it.

## Rule 3 — No destructive resets

Never solve migration or synchronization problems by deleting the database or resetting all data.

Create proper migrations.

## Rule 4 — One phase at a time

Do not start Phase 17 automatically after completing Phase 16.

Stop and wait for review.

## Rule 5 — Report what actually happened

Do not claim:

- tests passed unless they were run
- APK built unless it built
- two-device sync worked unless it was tested
- security was verified unless tested
- Phase 16 completed if only partial code exists

## Rule 6 — Small controlled changes

Do not make a giant uncontrolled rewrite.

Prefer:

1. inspect
2. plan
3. implement a bounded portion
4. test
5. inspect results
6. continue

---

# 29. Current Project Structure — Conceptual

The exact structure may have evolved, so inspect the repository before relying on this, but the intended architecture is approximately:

```text
lib/
├── core/
│   ├── config/
│   ├── database/
│   ├── network/
│   ├── router/
│   ├── services/
│   └── theme/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── today/
│   ├── tracking/
│   ├── habits/
│   ├── study/
│   ├── lifestyle/
│   ├── journal/
│   ├── wellbeing/
│   ├── couple/
│   ├── screen_time/
│   ├── goals/
│   ├── reminders/
│   └── sync/
│
└── shared/
    ├── widgets/
    ├── models/
    └── utilities/
```

Backend is conceptually:

```text
backend/
├── app/
│   ├── api/
│   ├── auth/
│   ├── db/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   └── sync/
│
├── alembic/
├── tests/
└── docker-compose.yml
```

Again: inspect actual repository structure before editing.

---

# 30. Known Future Work

After Journal + Wellbeing synchronization, remaining major areas include:

- Personal Goals synchronization
- Screen Time synchronization
- Reminders synchronization strategy if desired
- Couple/shared data synchronization
- Better couple permissions/access control
- Shared goals synchronization
- Shared habits synchronization
- Shared activities synchronization
- Memories synchronization
- Shared journal/couple-scoped synchronization
- Production deployment/hardening
- Backend observability
- account/device management
- conflict UI where appropriate
- sync diagnostics
- additional notification deep links

These should be handled in separate phases.

Do NOT implement them during Phase 16.

---

# 31. Product UX Rules

Keep the UI cohesive.

Avoid:

- giant screens containing every feature
- unnecessary notification spam
- fake statistics
- fake partner information
- excessive dashboards
- unnecessary bottom navigation items
- duplicating existing systems

Use the existing design language and reusable components.

---

# 32. Antigravity/Gemini Working Style

The user prefers:

- one phase at a time
- small controlled changes
- explicit verification
- copy/paste-friendly prompts
- Git commit/tag after stable milestones
- no automatic continuation to the next phase
- no destructive changes
- production-quality architecture
- explain important changes
- stop after the requested phase

If implementation is ambiguous, inspect the code and report the ambiguity instead of inventing an architecture.

---

# 33. FIRST ACTION IN THE NEW SESSION

Before implementing anything, run/inspect:

```bash
git status
git log --oneline --decorate -20
```

Then inspect:

- current schema version
- latest Drift migration state
- JournalRepository
- MoodRepository
- SyncEngine
- SyncQueue
- backend sync service/routes
- backend models
- Alembic migrations
- existing Journal/Mood tests
- current backend tests

Then determine exactly what Phase 16 work survived the quota interruption.

---

# 34. READY-TO-PASTE CONTINUATION PROMPT

Use the following prompt in the new ChatGPT/Gemini/Antigravity session.

---

## CONTINUATION PROMPT

You are continuing development of **HabitO**, an existing production-oriented Flutter + FastAPI offline-first life-management/couple application.

I am providing you with `HABITO_PROJECT_HANDOFF.md`, which is the project's current architectural handoff.

**Read the entire document before making changes.**

### Critical context

HabitO has completed Phases 1–15.

The Gemini/Antigravity quota reached its limit **while working on Phase 16**.

Therefore:

> **DO NOT assume Phase 16 is complete.**

The repository may contain a partial Phase 16 implementation.

Your first job is to inspect the current repository and determine exactly what survived.

### First, inspect — do not modify anything yet

Run:

```bash
git status
git log --oneline --decorate -20
```

Then inspect the actual code for:

- Drift schema/version
- JournalEntriesTable
- MoodLogsTable
- JournalRepository
- MoodRepository
- SyncQueue
- SyncEngine
- existing DTOs
- existing sync routing
- backend models
- backend migrations
- backend sync service
- Journal tests
- Mood tests
- sync tests
- backend tests

Also inspect whether there are uncommitted Phase 16 changes.

### Then report

Give me a concise status report:

1. What Phase 16 work is already implemented
2. What is partially implemented
3. What is missing
4. Any compile/test/migration problems
5. Current git status
6. Latest commit/tag
7. Exact recommended next implementation step

**Do not implement anything until this inspection report is complete.**

---

## Phase 16 Goal

Synchronize:

- JournalEntry
- MoodLog

Do NOT implement:

- personal goal synchronization
- screen-time synchronization
- reminders synchronization
- couple synchronization
- couple-scoped journal synchronization
- analytics synchronization
- search-index synchronization

### Required architecture

Local SQLite remains the UI source of truth.

Flow:

```text
UI
→ Riverpod
→ Repository
→ Drift/SQLite
→ SyncQueue
→ SyncEngine
→ Dio
→ FastAPI
→ PostgreSQL
```

Remote changes:

```text
FastAPI
→ SyncEngine
→ local DB
```

Remote application must NOT re-enter SyncQueue.

### Conflict policy

Use:

**server-authoritative last-write-wins**

Do not implement CRDT or intelligent journal text merging.

### Security

Ownership must come from JWT authentication.

Never trust a client-supplied `userId` for authorization.

User A must not:

- read User B's journal
- modify User B's journal
- read User B's mood
- modify User B's mood

A User A journal entry whose type is `shared` must NOT automatically be sent to User B through personal sync.

Couple-scoped synchronization is a future phase.

### Sensitive logging

Never log:

- journal body
- journal title unnecessarily
- mood values unnecessarily
- access tokens
- refresh tokens
- passwords

### Journal

Synchronize actual journal records.

Preserve:

- title
- body
- journal type
- tags
- timestamps
- ownership
- deletion/tombstone state

Local SQLite search must continue working after sync.

Do not synchronize a separate search index.

### Mood

Synchronize MoodLog source records.

Preserve existing timezone/logical-day behavior.

Do not synchronize:

- mood averages
- trends
- derived analytics

Existing wellbeing analytics should recalculate automatically from synchronized MoodLogs.

### Repository behavior

For local mutations:

```text
DB mutation + SyncQueue insertion
```

must happen atomically.

Implement remote application methods following the existing repository architecture.

Do not create duplicate repositories or bypass the repository layer.

### Tests

Add/maintain tests for:

- push
- pull
- ownership
- User A cannot access User B journal
- User A cannot modify User B journal
- User A cannot access User B mood
- User A cannot modify User B mood
- shared journal is not leaked through personal sync
- cursor progression
- loop prevention
- soft delete/tombstones
- offline mutation
- retry behavior where applicable

### Verification

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk
```

Also run backend migration/tests.

If possible, perform two-device verification:

Device A:
- create journal
- create mood
- sync

Device B:
- sync
- verify both appear
- edit journal
- sync

Device A:
- sync
- verify edit arrives

Also verify different-user isolation.

### Git

Only after everything genuinely passes:

```text
feat(sync): synchronize journal and wellbeing data
```

Tag:

```text
phase-16-journal-wellbeing-sync
```

Do NOT create the tag early.

### Most important working rule

Work **only on Phase 16**.

Do not start Phase 17.

Do not redesign HabitO.

Do not rewrite completed systems unnecessarily.

Do not delete the database.

Do not fabricate test results.

Do not claim manual tests passed unless they were actually performed.

After Phase 16 is complete, stop and wait for my review.

---

# 35. Final Handoff State

At the moment this document was last updated:

**Completed & Verified:** Phases 1–16

**Phase 16 Status:** Completed & Verified (Journal & Mood sync verified across backend models, Alembic migrations, DTOs, security tests, Flutter SyncEngine, repository atomic sync queueing, static analysis, unit tests, and APK build).

**Next Action:** Await user directive for starting Phase 17 (do NOT automatically begin Phase 17).

---

# END OF HABITO HANDOFF
