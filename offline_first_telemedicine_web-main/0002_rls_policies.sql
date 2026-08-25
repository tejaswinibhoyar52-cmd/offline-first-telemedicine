-- ============================================================================
-- MediCare Offline — 0002_rls_policies.sql
-- Row Level Security: patients see only their own data, doctors see only
-- their own patients/appointments, admins manage everything.
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.doctors enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.appointments enable row level security;
alter table public.medical_records enable row level security;
alter table public.prescriptions enable row level security;
alter table public.consultations enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.sync_conflicts enable row level security;
alter table public.health_articles enable row level security;

-- ----------------------------------------------------------------------------
-- Helper: current user's role, read once per statement via a stable function.
-- ----------------------------------------------------------------------------
create or replace function public.current_role_is(target_role text)
returns boolean as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.role = target_role
  );
$$ language sql stable security definer;

create or replace function public.is_admin()
returns boolean as $$
  select public.current_role_is('admin');
$$ language sql stable security definer;

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
create policy "profiles_select_self_or_admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

create policy "profiles_select_doctor_sees_patient" on public.profiles
  for select using (
    role = 'patient' and exists (
      select 1 from public.appointments a
      where a.patient_id = profiles.id and a.doctor_id = auth.uid()
    )
  );

create policy "profiles_select_patient_sees_doctor" on public.profiles
  for select using (
    role = 'doctor' -- doctor directory is browsable by any authenticated patient
  );

create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

create policy "profiles_update_self_or_admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- patients
-- ----------------------------------------------------------------------------
create policy "patients_select_self" on public.patients
  for select using (id = auth.uid() or public.is_admin());

create policy "patients_select_by_doctor" on public.patients
  for select using (
    exists (select 1 from public.appointments a where a.patient_id = patients.id and a.doctor_id = auth.uid())
  );

create policy "patients_insert_self" on public.patients
  for insert with check (id = auth.uid());

create policy "patients_update_self_or_admin" on public.patients
  for update using (id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- doctors (directory is publicly browsable to any authenticated user)
-- ----------------------------------------------------------------------------
create policy "doctors_select_any_authenticated" on public.doctors
  for select using (auth.role() = 'authenticated');

create policy "doctors_insert_self" on public.doctors
  for insert with check (id = auth.uid());

create policy "doctors_update_self_or_admin" on public.doctors
  for update using (id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- doctor_availability
-- ----------------------------------------------------------------------------
create policy "availability_select_any_authenticated" on public.doctor_availability
  for select using (auth.role() = 'authenticated');

create policy "availability_manage_own" on public.doctor_availability
  for all using (doctor_id = auth.uid() or public.is_admin())
  with check (doctor_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- appointments
-- ----------------------------------------------------------------------------
create policy "appointments_select_participant_or_admin" on public.appointments
  for select using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

create policy "appointments_insert_patient_self" on public.appointments
  for insert with check (patient_id = auth.uid() or public.is_admin());

create policy "appointments_update_participant_or_admin" on public.appointments
  for update using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- medical_records
-- ----------------------------------------------------------------------------
create policy "records_select_patient_doctor_admin" on public.medical_records
  for select using (
    patient_id = auth.uid()
    or public.is_admin()
    or exists (select 1 from public.appointments a where a.patient_id = medical_records.patient_id and a.doctor_id = auth.uid())
  );

create policy "records_insert_authorized" on public.medical_records
  for insert with check (
    uploaded_by = auth.uid() and (
      patient_id = auth.uid()
      or public.current_role_is('doctor')
      or public.is_admin()
    )
  );

create policy "records_update_uploader_or_admin" on public.medical_records
  for update using (uploaded_by = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- prescriptions
-- ----------------------------------------------------------------------------
create policy "prescriptions_select_participant_or_admin" on public.prescriptions
  for select using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

create policy "prescriptions_insert_doctor_self" on public.prescriptions
  for insert with check (doctor_id = auth.uid() or public.is_admin());

create policy "prescriptions_update_doctor_or_admin" on public.prescriptions
  for update using (doctor_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- consultations
-- ----------------------------------------------------------------------------
create policy "consultations_select_participant_or_admin" on public.consultations
  for select using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

create policy "consultations_insert_doctor_self" on public.consultations
  for insert with check (doctor_id = auth.uid() or public.is_admin());

create policy "consultations_update_doctor_or_admin" on public.consultations
  for update using (doctor_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- messages
-- ----------------------------------------------------------------------------
create policy "messages_select_participant_or_admin" on public.messages
  for select using (sender_id = auth.uid() or recipient_id = auth.uid() or public.is_admin());

create policy "messages_insert_sender_self" on public.messages
  for insert with check (sender_id = auth.uid());

-- ----------------------------------------------------------------------------
-- notifications
-- ----------------------------------------------------------------------------
create policy "notifications_select_own" on public.notifications
  for select using (user_id = auth.uid() or public.is_admin());

create policy "notifications_insert_system" on public.notifications
  for insert with check (true); -- notifications are created on behalf of users by trusted app logic

create policy "notifications_update_own" on public.notifications
  for update using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- sync_conflicts — admin-only review surface
-- ----------------------------------------------------------------------------
create policy "sync_conflicts_admin_only_select" on public.sync_conflicts
  for select using (public.is_admin());

create policy "sync_conflicts_insert_authenticated" on public.sync_conflicts
  for insert with check (auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- health_articles — public educational content, readable by all authenticated users
-- ----------------------------------------------------------------------------
create policy "health_articles_select_any_authenticated" on public.health_articles
  for select using (auth.role() = 'authenticated');

create policy "health_articles_admin_manage" on public.health_articles
  for all using (public.is_admin()) with check (public.is_admin());
