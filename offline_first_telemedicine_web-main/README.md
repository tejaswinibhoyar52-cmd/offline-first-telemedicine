# MediCare Offline — Offline-First Telemedicine Platform

**Healthcare Anywhere, Even Without Internet.**

A final-year engineering project: a full-stack telemedicine platform designed for rural and
low-connectivity areas. Patients and doctors can continue essential healthcare activities —
booking appointments, viewing records, writing consultation notes, messaging — even with zero
internet connectivity, and every change synchronizes automatically to a central Supabase database
the moment connectivity returns.

---

## 1. Problem Statement

Healthcare services in rural and remote areas are often affected by poor or unreliable internet
connectivity, making remote consultations, appointment management, and access to medical records
difficult. MediCare Offline is built so that connectivity is a convenience, not a dependency.

## 2. Objectives & Expected Outcomes

- Improve healthcare access in rural areas
- Enable reliable remote consultation
- Provide better patient record management
- Reduce unnecessary travel for patients
- Increase healthcare service continuity
- Support efficient doctor-patient communication
- Guarantee reliable offline data access
- Automatically synchronize data when connectivity returns

## 3. Features

| Area | What's implemented |
|---|---|
| **Auth** | Supabase Auth (email/password), role-based (patient / doctor / admin), offline-cached profile |
| **Appointments** | Search/filter doctors, book, cancel, accept/reject/complete, offline booking queue |
| **Medical Records** | Blood/X-ray/ECG/diabetes/consultation records, metadata cached offline, files in private Supabase Storage |
| **Prescriptions** | Multi-medicine structured prescriptions, doctor-authored only (no AI auto-prescribing) |
| **Consultations** | Offline note-taking (symptoms/observations/summary/follow-up) + clearly labeled WebRTC-ready video prototype |
| **Messaging** | Patient ↔ doctor threads, offline messages marked `PENDING SYNC`, auto-send on reconnect |
| **Sync Engine** | IndexedDB-backed sync queue, deterministic conflict resolution, sync history, retry/clear controls |
| **Health Assistant** | Offline FAQ knowledge base (English/Hindi/Marathi), voice input/output, no diagnosis claims |
| **Admin** | Platform-wide stats, charts, patients/doctors/appointments/records/prescriptions tables, sync oversight, reports |
| **PWA** | Installable, custom service worker, offline fallback page, app-shell caching |

## 4. Architecture

```
src/
  components/   Shared UI (layout shell, badges, toasts, sync dashboard)
  pages/        Route-level screens for patient / doctor / admin
  hooks/        useAuth, useSync, useNetworkStatus (React contexts)
  services/     Domain logic: appointments, records, prescriptions, etc.
  offline/      Sync queue, sync service, conflict resolution, device id
  db/           IndexedDB schema (via `idb`) + generic offline CRUD helpers
  lib/          Supabase client, small utilities
  types/        Shared domain + database types

public/
  sw.js             Hand-written service worker (app-shell cache, offline fallback, sync bridge)
  manifest.json     PWA manifest

supabase/
  migrations/       SQL: schema, RLS policies, storage bucket
  seed.sql          Demo data instructions + health articles
```

### Offline-first approach

Every write in the app follows a single path, whether you're online or offline:

```
User action
   │
   ▼
Write to IndexedDB (src/db)              ← always durable, instantly
   │
   ▼
Enqueue a Sync Record (src/offline/syncQueue.ts)
   │
   ▼
If online right now → sync engine attempts to push immediately
If offline           → record simply waits in the queue
   │
   ▼
On reconnect (browser 'online' event, or Background Sync API message
from the service worker) → runSync() processes the queue in order
```

This means there is no separate "offline mode" code path that diverges from
the "online mode" code path — the UI always reads/writes through the same
service functions, which are cache-first and sync-aware.

### Synchronization algorithm

`src/offline/syncService.ts` processes the queue in creation order:

```
PENDING → SYNCING → send to Supabase → validate → resolve conflict (if any)
        → update local IndexedDB copy → SYNCED (or FAILED / CONFLICT)
```

Every sync run appends an entry to sync history (visible on the `/sync` pages),
and updates the "last sync" timestamp shown in the app header.

### Conflict resolution

Every syncable record carries `version` (integer, incremented on each write) and
`updated_at`. When a local write conflicts with a remote copy that changed since
the local device last saw it:

1. Compare `version` — higher wins.
2. If tied, compare `updated_at` — newer wins.
3. If identical, it's not a real conflict (same edit).
4. Whichever side loses is **not silently discarded** — a `sync_conflicts` row is
   written (`supabase/migrations/0001_init_schema.sql`) so an admin can review it
   under **Admin → Sync**.

This is a deliberately simple, deterministic strategy appropriate for a prototype;
see "Future Scope" for a fuller CRDT/manual-merge approach.

## 5. Database Schema

See `supabase/migrations/0001_init_schema.sql` for full DDL. Tables:
`profiles`, `patients`, `doctors`, `doctor_availability`, `appointments`,
`medical_records`, `prescriptions`, `consultations`, `messages`, `notifications`,
`sync_conflicts`, `health_articles`. All use UUID primary keys, `created_at` /
`updated_at`, foreign keys, and indexes on the columns used for RLS and lookups.

## 6. Security

- **Row Level Security** (`0002_rls_policies.sql`) is enabled on every table.
  Patients can only read/write their own records; doctors can only see patients
  they have an appointment with; admins have full access via a `is_admin()`
  helper function.
- **Storage** (`0003_storage.sql`): medical documents live in a **private**
  bucket, gated by the same ownership rules, accessed only via short-lived
  signed URLs — never public links.
- **No service-role key** ever appears in frontend code. Only the public
  anon key is used client-side, matching Supabase's intended security model.
- All Supabase credentials are read from environment variables (`.env`), which
  is git-ignored.

## 7. Technology Stack

**Frontend:** React 18, TypeScript, Vite, Tailwind CSS, React Router, Recharts, `idb` (IndexedDB), lucide-react icons
**Backend:** Supabase (PostgreSQL, Auth, Storage, Row Level Security)
**Offline:** IndexedDB, custom Service Worker, Background Sync API (where supported), browser online/offline events

## 8. Local Development

```bash
# 1. Install dependencies
npm install

# 2. Configure Supabase
cp .env.example .env
# then edit .env with your project's URL + anon key

# 3. Run the dev server
npm run dev
```

### Supabase project setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run the migrations **in order**:
   - `supabase/migrations/0001_init_schema.sql`
   - `supabase/migrations/0002_rls_policies.sql`
   - `supabase/migrations/0003_storage.sql`
3. Copy your Project URL and anon public key into `.env`.
4. (Optional) Seed demo data — see `supabase/seed.sql` for step-by-step instructions,
   since Supabase Auth users must be created via the dashboard/CLI/`/register`
   page before their profile rows can be inserted.

### Environment variables

| Variable | Where used | Notes |
|---|---|---|
| `VITE_SUPABASE_URL` | `src/lib/supabaseClient.ts` | Your project's REST URL |
| `VITE_SUPABASE_ANON_KEY` | `src/lib/supabaseClient.ts` | Public anon key only — never the service role key |

## 9. How to Test Offline Mode

1. Log in, then open any dashboard.
2. Click **Simulate Offline Mode** in the header (works even with real internet —
   it's a UI-level override for demos), or actually disconnect your network /
   use your browser DevTools' Network → Offline throttling.
3. Notice the header badge switches to `🟠 Offline Mode` and a banner appears.
4. Try booking an appointment, adding a consultation note, or sending a message —
   these all succeed and show as queued (`PENDING SYNC` for messages, visible in
   the Sync Queue table).
5. Click **Restore Connection** (or turn your real network back on).
6. Watch the "Connection restored. Synchronizing your data…" banner, then check
   `/patient/sync`, `/doctor/sync`, or `/admin/sync` to see the queue drain to
   `SYNCED` and a new row appear in Sync History.

## 10. How to Test Synchronization

- Go to any `/sync` page.
- **Sync Now** manually triggers a sync pass.
- **Retry Failed** re-attempts anything marked `FAILED`.
- **Clear Completed** removes `SYNCED` rows from the visible queue (they remain
  correctly persisted in Supabase).
- To see conflict resolution in action, edit the same appointment from two
  different browser sessions while one is offline, then reconnect — the
  Conflicts panel will show which version won and why.

## 11. Demo Credentials

Demo accounts must be created once (Supabase Auth requires user creation via
the dashboard, CLI, or the app's own `/register` page — not plain SQL). See
`supabase/seed.sql` for the suggested demo accounts and matching seed rows:

```
Patient: ramesh.patil@demo.medicare / Demo@1234
Doctor:  anjali.verma@demo.medicare / Demo@1234
Admin:   admin@demo.medicare        / Demo@1234  (set role via SQL after signup)
```

## 12. Future Scope

- Real WebRTC video consultation (the UI/data model is ready; see `src/pages/patient/Consultation.tsx`)
- A server-side Edge Function for the Health Assistant backed by a real AI model,
  keeping API keys off the client (integration point documented in
  `src/services/healthAssistantService.ts`)
- Push notifications via the Web Push API
- More sophisticated conflict resolution (manual merge UI, field-level merging)
- SMS/USSD fallback channel for appointment reminders in extremely low-connectivity areas

## 13. Limitations

- This is a prototype for academic demonstration, not a certified medical device.
- Video consultation is a labeled placeholder, not a working WebRTC call.
- The Health Assistant answers from a small local FAQ; it is not a diagnostic tool.
- Conflict resolution uses a simple deterministic rule, not a full CRDT merge.

## 14. Healthcare Safety Disclaimer

MediCare Offline is an academic project and **is not a substitute for professional
medical advice, diagnosis, or treatment**. The Health Assistant module provides
general educational information only and explicitly avoids diagnosing conditions.
For any medical emergency, seek immediate in-person care or contact local
emergency services — do not rely on this application.
