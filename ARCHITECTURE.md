# C2C Marketplace — Architecture

This document is the **single source of truth** for how the backend (and how the Flutter client should integrate) is structured. Follow it for every new feature.

## Product vision

**Not** a simple storefront. This is a **consumer-to-consumer (C2C)** marketplace where users can:

| Capability | Description |
|------------|-------------|
| **List / buy** | Products with **variants** (e.g. size, color), each with **stock** and **price**. |
| **Swap** | A user offers **their** listed product in exchange for **another** user’s product. The counterparty **accepts** or **rejects**. |
| **Workshop** | After both sides agree on a swap, an **admin** must **approve** in the workshop flow. Products are **verified** before **ownership transfer**. |
| **Escrow** | If the two sides’ agreed values differ, the **difference** is held in **escrow** until the swap is completed or cancelled per your rules. |

## Tech stack

| Layer | Choice |
|-------|--------|
| API | Node.js + **Express**, **REST** |
| Data | **PostgreSQL** (via `pg` connection pool) |
| Auth | **JWT** (Bearer tokens) |
| Client | **Flutter** (consumes JSON API; no server-side views) |

## Backend folder layout

| Path | Responsibility |
|------|----------------|
| `src/config/` | Env loading, DB pool, app-wide config |
| `src/routes/` | HTTP paths and HTTP verbs only; wire controllers + validators |
| `src/controllers/` | Parse request, call **services**, map response (thin) |
| `src/services/` | Business rules, transactions, orchestration (fat) |
| `src/models/` | DB access helpers / repositories (SQL per domain area) |
| `src/middlewares/` | Auth, roles, validation result handling, errors |
| `src/utils/` | Shared helpers (errors, IDs, money helpers later) |
| `src/constants/` | Roles, order/swap statuses (avoid magic strings) |
| `db/migrations/` | Versioned SQL migrations (add files as the schema grows) |

**Rule:** Routes stay dumb; controllers stay thin; **services** own workflows (e.g. “accept swap → create escrow → enqueue workshop”).

## REST & JSON conventions

- **Base path:** `/api/...`
- **Success body:**

  ```json
  { "success": true, "data": { } }
  ```

- **Error body:**

  ```json
  { "success": false, "error": { "code": "SOME_CODE", "message": "Human-readable message" } }
  ```

- **Auth:** `Authorization: Bearer <access_token>`
- **Validation:** Use `express-validator` in route chains; on failure return **400** with `error.code` like `VALIDATION_ERROR` and optional `details` later if needed.

## Domain modules (reference for future work)

Names are indicative; exact tables will land in migrations.

1. **Users & auth** — register/login, password hashing (`bcrypt`), JWT payload at minimum: `sub` (user id), `role` (`user` | `admin`).
2. **Products** — product + **variants** (attributes JSON or typed columns), inventory per variant.
3. **Orders** — buyer, line items, amounts, **status lifecycle** (e.g. pending → paid → shipped → completed / cancelled).
4. **Swaps** — proposer, target product, offered product, status (e.g. pending → accepted/rejected → workshop_pending → …).
5. **Workshop** — queue of swaps (or steps) needing **admin approval** before transfer.
6. **Escrow** — ledger/holds for **price difference** on swaps; release/refund rules in services.
7. **Admin** — APIs to list/approve/reject workshop items, moderate products, oversee swaps.

Keep **status values** in `src/constants/` and reuse everywhere (API + DB check constraints where possible).

## Error handling

- Throw `AppError` (or pass to `next(err)`) for operational errors with `statusCode` + `code`.
- Unknown errors are logged and returned as **500** without leaking internals in production.
- Use `asyncHandler` on async route handlers so rejections reach the global error middleware.

## Database

- Use **`DATABASE_URL`** (PostgreSQL connection string).
- Prefer **migrations** in `db/migrations/` (numbered SQL files) over ad-hoc DDL in application code.
- Use **transactions** in services when a single user action touches multiple rows (orders, swaps, escrow).

## Flutter integration notes

- Treat the API as versioned later if needed (`/api/v1/...`); start with `/api` unless you add versioning in a dedicated task.
- Expect stable `success` / `error` shapes for global error parsing.
- Store JWT securely (platform-specific secure storage).

---

When adding a feature, update this file only if you introduce a **new cross-cutting rule** (new envelope field, auth scheme, or module boundary).
