# E-Ticaret API

C2C marketplace **REST API** (Node.js + Express + PostgreSQL). The mobile/web client is intended to be **Flutter**; this repo is the backend only.

See **[ARCHITECTURE.md](./ARCHITECTURE.md)** for domain features (products & variants, orders, swaps, workshop approvals, escrow), folder layout, API JSON conventions, and consistency rules for future work.

## Prerequisites

- [Node.js](https://nodejs.org/) 18 or newer
- [PostgreSQL](https://www.postgresql.org/) (when you start using the database; migrations live in `db/migrations/`)

## Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create a `.env` file in the project root (you can copy from the example):

   ```bash
   copy .env.example .env
   ```

   On macOS/Linux:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` if you need a different `PORT` (default `3000`).

### PostgreSQL

Set **`DATABASE_URL`** *or* **`PGUSER`** + **`PGDATABASE`** (and optional **`PGHOST`**, **`PGPORT`**, **`PGPASSWORD`**) in `.env`. See `.env.example`.

Verify the DB is reachable:

```bash
npm run db:test
```

This runs a simple `SELECT NOW(), current_database()` via the shared `query` helper in `src/config/database.js`.

Create the **`users`** table (SQL: `db/migrations/001_create_users.sql`):

```bash
npm run db:ensure-users
```

Or run the same script in `psql` / your SQL client. Programmatically: `ensureUsersTable()` from `src/models/user.model.js`.

Create **`categories`** and **`products`** (`db/migrations/002_*.sql`, `003_*.sql`) — run after `users` exists:

```bash
npm run db:ensure-catalog
```

Programmatically: `ensureCatalogTables()` from `src/models/catalog.model.js`.

## Run

- **Production-style (no auto-restart):**

  ```bash
  npm start
  ```

- **Development (restarts on file changes, Node 18+):**

  ```bash
  npm run dev
  ```

The server prints the URL it listens on (e.g. `http://localhost:3000`).

## Health check

- `GET /api/health` — returns JSON:

  ```json
  {
    "success": true,
    "data": { "status": "ok", "timestamp": "<ISO8601>" }
  }
  ```

Example:

```bash
curl http://localhost:3000/api/health
```

## Authentication

Requires **`JWT_SECRET`** in `.env` for login (token issuance). Ensure the **`users`** table exists (`npm run db:ensure-users`).

| Method | Path | Body (JSON) | Success |
|--------|------|-------------|---------|
| `POST` | `/api/auth/register` | `{ "email", "password" }` (password ≥ 8 chars) | `201` — `{ user: { id, email, created_at } }` |
| `POST` | `/api/auth/login` | `{ "email", "password" }` | `200` — `{ token, user: { id, email, created_at } }` |

Errors use `{ "success": false, "error": { "code", "message", "details?" } }` (validation includes `details`).

### Protected route example

| Method | Path | Headers | Success |
|--------|------|---------|---------|
| `GET` | `/api/profile` | `Authorization: Bearer <access_token>` | `200` — `{ "user": { "id", "email", "created_at", "role" } }` |

Missing/invalid/expired token → **401** `UNAUTHORIZED`.

### Products (requires `products` table: `npm run db:ensure-catalog`)

| Method | Path | Auth | Notes |
|--------|------|------|--------|
| `GET` | `/api/products` | No | Query: `page` (default 1), `limit` (default 20, max 100) |
| `GET` | `/api/products/:id` | No | |
| `POST` | `/api/products` | Bearer | Body: `title`, `price`, optional `description`, `category_id`, `variants[]` (`name`, `value`, `price`, `stock`) |
| `PUT` | `/api/products/:id` | Bearer | Seller only; at least one of product fields **or** `variants` (replaces all variants when sent) |
| `DELETE` | `/api/products/:id` | Bearer | Seller only |

List response includes `pagination`: `{ page, limit, total, total_pages }`.

### Orders (requires `005_create_orders.sql` via `npm run db:ensure-catalog`)

Statuses: `PENDING`, `SHIPPED`, `DELIVERED` (new orders are `PENDING`). Line-item `price` is the variant price at checkout.

| Method | Path | Auth | Notes |
|--------|------|------|--------|
| `POST` | `/api/orders` | Bearer | Body: `{ "items": [ { "variant_id", "quantity" } ] }` — merges duplicate variants, reduces `product_variants.stock` in a transaction |
| `GET` | `/api/orders` | Bearer | Current user’s orders; query: `page`, `limit` (same defaults as products) |

### Swaps (`006_create_swaps.sql` via `npm run db:ensure-catalog`)

Statuses: `PENDING`, `ACCEPTED`, `REJECTED`, `WORKSHOP`. The **receiver** is the owner of `product_requested_id`.

| Method | Path | Auth | Notes |
|--------|------|------|--------|
| `POST` | `/api/swaps` | Bearer | Body: `product_offered_id`, `product_requested_id` — you must own the offered product; cannot request your own product |
| `PUT` | `/api/swaps/:id/accept` | Bearer | Receiver only — locks both products (`is_available: false`), `PENDING` → `WORKSHOP` |
| `PUT` | `/api/swaps/:id/reject` | Bearer | Receiver only — `PENDING` → `REJECTED` |

### Workshop / work orders (`008`–`009` via `npm run db:ensure-catalog`)

`work_orders` rows are created when a swap moves to **`WORKSHOP`** (one queue row per swap). Admins need `users.role = 'admin'` (see below).

| Method | Path | Auth | Notes |
|--------|------|------|--------|
| `GET` | `/api/workorders` | Admin Bearer | Paginated list; each entry includes nested `swap` |
| `PUT` | `/api/workorders/:id/approve` | Admin | Transfers both products, sets `is_available: true`, work order **APPROVED**, swap **COMPLETED** |
| `PUT` | `/api/workorders/:id/reject` | Admin | Unlocks both products (`is_available: true`), work order **REJECTED**, swap **CANCELLED** |

**Admin:** after migration `009_add_users_role.sql`, set e.g. `UPDATE users SET role = 'admin' WHERE email = 'you@example.com';` then log in again so the JWT includes the admin role.

### Escrow (`010_create_escrows.sql`)

When a swap is accepted into **`WORKSHOP`**, if the two listings’ base **`products.price`** values differ, an **`escrows`** row is created: **`amount`** = absolute difference, **`status`** = **`HELD`**. There is at most one escrow row per **`swap_id`**.

On workshop **approve** or **reject**, that row is set to **`RELEASED`** (if it existed). API responses may include **`escrow`** on swap accept and work-order approve/reject.

## Project layout

| Path | Role |
|------|------|
| `src/server.js` | Entry: loads config and starts HTTP server |
| `src/app.js` | Express app (CORS, JSON, routes, 404, errors) |
| `src/config/` | Environment (`env.js`), PostgreSQL pool + `query` (`database.js`) |
| `src/routes/` | HTTP paths; combine with validators + controllers |
| `src/controllers/` | Thin handlers: call services, send JSON |
| `src/services/` | Business logic and transactions |
| `src/models/` | DB / repository helpers (SQL) |
| `src/middlewares/` | Auth (JWT), `asyncHandler`, error handling |
| `src/validators/` | `express-validator` chains (per route) |
| `src/utils/` | Shared helpers (e.g. `AppError`) |
| `src/constants/` | Roles and status enums |
| `db/migrations/` | SQL migrations |
