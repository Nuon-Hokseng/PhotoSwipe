# CLAUDE_ARCHITECTURE.md — Structure & Contracts (Load When Planning)

**Stack:** Flutter | Supabase | Express/Node.js or FastAPI

---

## Flutter App Folder Structure

```
lib/
├── features/
│   ├── dashboard/              # Person 3 — analytics dashboard UI
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/          # or bloc/
│   │   └── dashboard_types.dart
│   ├── analytics/              # Person 3 — stats, session, history
│   │   ├── services/
│   │   ├── repositories/
│   │   └── analytics_types.dart
│   ├── ai/                     # Person 3 — blur, duplicate, screenshot
│   │   ├── services/
│   │   └── ai_types.dart
│   ├── swipe/                  # Person 1 — gesture engine, swipe UI
│   ├── gallery/                # Person 2 — gallery access, permissions
│   ├── queue/                  # Person 2 — photo queue, session state
│   └── delete/                 # Person 2 — delete workflow
│
├── shared/
│   ├── widgets/                # reusable UI components
│   ├── providers/              # shared app-wide state
│   ├── utils/                  # pure Dart utility functions
│   ├── constants/              # all named constants
│   ├── types/                  # shared models agreed by all members
│   └── theme/                  # colors, spacing, text styles
│
├── services/
│   ├── supabase/               # Supabase client abstraction
│   ├── permissions/            # device permission abstraction
│   └── logger/                 # structured logger
│
└── utils/
    ├── analytics/              # Person 3
    ├── image_analysis/         # Person 3
    ├── swipe/                  # Person 1
    └── gallery/                # Person 2
```

---

## Backend Folder Structure

### Express / Node.js
```
backend/
├── src/
│   ├── routes/
│   │   └── analytics.routes.ts
│   ├── controllers/
│   │   └── analytics.controller.ts
│   ├── services/
│   │   └── analytics.service.ts
│   ├── repositories/
│   │   └── analytics.repository.ts
│   ├── middleware/
│   │   ├── auth.ts
│   │   └── validate.ts
│   ├── types/
│   └── config/
│       └── supabase.ts
```

### FastAPI (Python)
```
backend/
├── app/
│   ├── routers/
│   │   └── analytics.py
│   ├── services/
│   │   └── analytics_service.py
│   ├── repositories/
│   │   └── analytics_repository.py
│   ├── models/
│   │   └── analytics.py        # Pydantic models
│   ├── middleware/
│   └── config/
│       └── supabase.py
```

---

## Layer Rules

| Layer | Can Call | Cannot Call |
|---|---|---|
| Widget/Screen | Provider/Bloc | Services, Supabase directly |
| Provider/Bloc | Services | UI widgets, Supabase directly |
| Service | Repository, Utils | UI, Provider/Bloc |
| Repository | Supabase client only | Everything else |
| Util | Nothing (pure) | Side effects |

---

## Supabase Rules

- All Supabase calls go inside **Repository files only**.
- Every table must have **Row Level Security (RLS)** enabled.
- Never expose the `service_role` key on the client — Flutter uses `anon` key only.
- Use Supabase **Edge Functions** for any server-side logic that needs the service key.

```dart
// ✅ Repository — only place Supabase is touched
class AnalyticsRepository {
  final SupabaseClient _client;

  Future<List<Session>> getAllSessions() async {
    final response = await _client
        .from('sessions')
        .select()
        .order('started_at', ascending: false);
    return response.map((e) => Session.fromJson(e)).toList();
  }
}

// ❌ Never do this inside a widget or service
Supabase.instance.client.from('sessions').select()
```

---

## Backend Pattern

```
Route (≤30 lines) → Controller (≤50 lines) → Service (≤150 lines) → Repository (≤100 lines) → Supabase
```

```typescript
// Express example
// repository — Supabase queries only
class AnalyticsRepository {
  async getSessions(): Promise<Session[]>
  async saveSession(session: Session): Promise<void>
}

// service — business logic only
class AnalyticsService {
  constructor(private repo: AnalyticsRepository) {}
  async getStats(): Promise<AnalyticsStats>
}

// controller — ≤15 lines per handler
async function handleGetStats(req, res) {
  const result = await analyticsService.getStats()
  res.json(result)
}
```

```python
# FastAPI example
# repository
class AnalyticsRepository:
    async def get_sessions(self) -> list[Session]: ...
    async def save_session(self, session: Session) -> None: ...

# service
class AnalyticsService:
    def __init__(self, repo: AnalyticsRepository): ...
    async def get_stats(self) -> AnalyticsStats: ...

# router handler — short, delegates to service
@router.get("/stats")
async def get_stats(service: AnalyticsService = Depends()):
    return await service.get_stats()
```

---

## Shared Types — Agreed by All Members

```dart
// lib/shared/types/photo.dart
class PhotoItem {
  final String id;
  final String uri;
  final int size;         // bytes
  final int createdAt;    // unix timestamp

  const PhotoItem({
    required this.id,
    required this.uri,
    required this.size,
    required this.createdAt,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}

// lib/shared/types/swipe.dart
class SwipeAction {
  final String photoId;
  final String action;    // 'keep' | 'delete'
  final int timestamp;
}
```

---

## Cross-Team API Contracts

| Owner | Exposed API |
|---|---|
| Person 1 | `getSwipeHistory()`, `getCurrentCard()` |
| Person 2 | `getPhotoMetadata()`, `getDeleteQueue()`, `getTotalStorageUsed()` |
| Person 3 | `getStats()`, `detectBlur()`, `detectDuplicate()`, `generateRecommendations()` |

```dart
// ✅ Correct — consume their service
final history = await swipeService.getSwipeHistory();

// ❌ Never — reaching into their internals
import 'package:app/features/swipe/stores/swipe_store.dart';
```

---

## Git Branch Rules

```
main          ← protected, PR only
develop       ← integration branch
feature/swipe-engine      ← Person 1
feature/gallery-engine    ← Person 2
feature/analytics-ai      ← Person 3
```

- Work only inside owned folders.
- Shared type changes → team discussion first.
- PR into `develop` only — never push to `main`.
- Never create: `utils.dart`, `helpers.dart`, `constants.dart` at root level.

---

*Return to CLAUDE.md for daily coding rules.*