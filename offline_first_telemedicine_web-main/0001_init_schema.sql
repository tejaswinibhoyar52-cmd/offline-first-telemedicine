-- ============================================================================
-- MediCare Offline — 0001_init_schema.sql
-- Core schema for the offline-first telemedicine platform.
-- Run this in the Supabase SQL editor, or via `supabase db push`.
-- ============================================================================

create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- profiles: one row per authenticated user (patient, doctor, or admin)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  role text not null check (role in ('patient', 'doctor', 'admin')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  device_id text
);
create index if not exists idx_profiles_role on public.profiles (role);

-- ----------------------------------------------------------------------------
-- patients: patient-specific fields, 1:1 with profiles
-- ----------------------------------------------------------------------------
create table if not exists public.patients (
  id uuid primary key references public.profiles (id) on delete cascade,
  date_of_birth date,
  gender text,
  blood_group text,
  address text,
  emergency_contact text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- doctors: doctor-specific fields, 1:1 with profiles
-- ----------------------------------------------------------------------------
create table if not exists public.doctors (
  id uuid primary key references public.profiles (id) on delete cascade,
  specialty text not null default 'General Physician',
  qualification text,
  years_experience integer,
  consultation_fee numeric(10, 2),
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_doctors_specialty on public.doctors (specialty);

-- ----------------------------------------------------------------------------
-- doctor_availability
-- ----------------------------------------------------------------------------
create table if not exists public.doctor_availability (
  id uuid primary key default uuid_generate_v4(),
  doctor_id uuid not null references public.doctors (id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  slot_minutes integer not null default 30
);
create index if not exists idx_availability_doctor on public.doctor_availability (doctor_id);

-- ----------------------------------------------------------------------------
-- appointments
-- ----------------------------------------------------------------------------
create table if not exists public.appointments (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  doctor_id uuid not null references public.doctors (id) on delete cascade,
  scheduled_date date not null,
  scheduled_time time not null,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
  reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  device_id text
);
create index if not exists idx_appointments_patient on public.appointments (patient_id);
create index if not exists idx_appointments_doctor on public.appointments (doctor_id);
create index if not exists idx_appointments_status on public.appointments (status);
create index if not exists idx_appointments_date on public.appointments (scheduled_date);

-- ----------------------------------------------------------------------------
-- medical_records
-- ----------------------------------------------------------------------------
create table if not exists public.medical_records (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  uploaded_by uuid not null references public.profiles (id),
  record_type text not null check (record_type in ('blood_report', 'xray', 'ecg', 'diabetes', 'consultation', 'other')),
  title text not null,
  description text,
  file_path text,
  record_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  device_id text
);
create index if not exists idx_records_patient on public.medical_records (patient_id);

-- ----------------------------------------------------------------------------
-- prescriptions (medicines stored as JSONB array)
-- ----------------------------------------------------------------------------
create table if not exists public.prescriptions (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  doctor_id uuid not null references public.doctors (id) on delete cascade,
  consultation_id uuid,
  diagnosis text not null,
  medicines jsonb not null default '[]'::jsonb,
  issued_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  device_id text
);
create index if not exists idx_prescriptions_patient on public.prescriptions (patient_id);
create index if not exists idx_prescriptions_doctor on public.prescriptions (doctor_id);

-- ----------------------------------------------------------------------------
-- consultations
-- ----------------------------------------------------------------------------
create table if not exists public.consultations (
  id uuid primary key default uuid_generate_v4(),
  appointment_id uuid references public.appointments (id) on delete set null,
  patient_id uuid not null references public.patients (id) on delete cascade,
  doctor_id uuid not null references public.doctors (id) on delete cascade,
  mode text not null default 'offline_notes' check (mode in ('video', 'offline_notes')),
  status text not null default 'completed' check (status in ('scheduled', 'in_progress', 'completed')),
  symptoms text,
  observations text,
  summary text,
  follow_up text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  device_id text
);
create index if not exists idx_consultations_patient on public.consultations (patient_id);
create index if not exists idx_consultations_doctor on public.consultations (doctor_id);

alter table public.prescriptions
  add constraint fk_prescriptions_consultation
  foreign key (consultation_id) references public.consultations (id) on delete set null;

-- ----------------------------------------------------------------------------
-- messages
-- ----------------------------------------------------------------------------
create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  thread_id text not null,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  status text not null default 'sent' check (status in ('pending', 'sent', 'delivered')),
  created_at timestamptz not null default now(),
  device_id text
);
create index if not exists idx_messages_thread on public.messages (thread_id);

-- ----------------------------------------------------------------------------
-- notifications
-- ----------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications (user_id);

-- ----------------------------------------------------------------------------
-- sync_conflicts: audit trail of conflicts resolved by the client sync engine
-- ----------------------------------------------------------------------------
create table if not exists public.sync_conflicts (
  id uuid primary key default uuid_generate_v4(),
  entity_type text not null,
  entity_id uuid not null,
  local_payload jsonb not null,
  remote_payload jsonb not null,
  resolution text not null check (resolution in ('local_wins', 'remote_wins', 'unresolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- ----------------------------------------------------------------------------
-- health_articles: offline-cacheable educational content
-- ----------------------------------------------------------------------------
create table if not exists public.health_articles (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  language text not null check (language in ('en', 'hi', 'mr')),
  category text not null,
  body text not null
);

-- ----------------------------------------------------------------------------
-- updated_at trigger helper
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
declare
  t text;
begin
  foreach t in array array['profiles','patients','doctors','appointments','medical_records','prescriptions','consultations']
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on public.%I; create trigger trg_set_updated_at before update on public.%I for each row execute function public.set_updated_at();',
      t, t
    );
  end loop;
end $$;
