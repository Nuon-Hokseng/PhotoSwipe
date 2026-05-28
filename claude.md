# CLAUDE.md — Core Rules (Always Load)

**Project:** PhotoSwipe — AI-Powered Photo Cleanup App
**Stack:** Flutter (Dart) | Supabase | Express/Node.js or FastAPI (Python)

---

## Non-Negotiable Rules

**Functions**
- One input → one output → pass to next function. No functions that do multiple jobs.
- If a function exists already — use it. Never recreate existing logic.
- All async functions return a `Result` type or use proper error handling — never throw silently.

**Layers — never skip**
```
Widget → Provider/Bloc → Service → Repository → Supabase/DB
```
No Supabase calls in widgets. No business logic in UI. No DB calls outside repositories.

**Code Quality**
- No `dynamic` type — everything must be typed in Dart.
- No magic numbers — all constants go in a `constants/` file with a name.
- No hardcoded strings — use a constants/strings file.
- No duplicate code — if written twice, extract to shared utils immediately.
- No `print()` in production — use a shared logger service.

**File Length Limits — split before exceeding**
| File Type | Max Lines |
|---|---|
| Controller / Route handler | 50 |
| Service | 150 |
| Repository | 100 |
| Utility | 80 |
| Widget | 100 |

**Error Handling — Dart**
```dart
// Use a Result type or sealed class pattern
Future<Result<T, AppError>> doSomething() async {
  try {
    final data = await someOperation();
    return Result.success(data);
  } catch (e) {
    return Result.failure(AppError.unknown);
  }
}
```

**Error Handling — Backend (Express or FastAPI)**
```typescript
// Express
async function handler(req, res) {
  try {
    const data = await service.doSomething()
    res.json({ data })
  } catch (e) {
    res.status(500).json({ error: 'Internal error' })
  }
}
```
```python
# FastAPI
@router.get("/stats")
async def get_stats():
    try:
        return await analytics_service.get_stats()
    except AppError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

**Security**
- Minimum permissions — request only what is needed, when needed.
- No secrets hardcoded — use `.env` / environment variables.
- All Supabase queries go through Row Level Security (RLS) — never bypass it.
- Validate all inputs on the backend before any DB operation.

**Git Commits**
```
feat(scope): short description
fix(scope): short description
perf(scope): short description
test(scope): short description
```

---

## Before Writing Any Code

1. Does this function already exist?
2. Does each function do exactly one thing?
3. Are all errors handled explicitly?
4. Any magic numbers or hardcoded strings?
5. Does this file exceed its line limit?

---

*Load CLAUDE_ARCHITECTURE.md when planning. Load CLAUDE_PERSON3.md when coding.*