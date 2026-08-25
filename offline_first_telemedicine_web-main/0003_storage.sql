-- ============================================================================
-- MediCare Offline — 0003_storage.sql
-- Private storage bucket for uploaded medical documents (X-rays, reports).
-- Files are never public — access is only via short-lived signed URLs
-- requested by an authorized user (see src/services/recordService.ts).
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('medical-documents', 'medical-documents', false)
on conflict (id) do nothing;

-- Path convention: {patient_id}/{uuid}-{filename}
-- so the first path segment can be checked against auth.uid() cheaply.

create policy "medical_documents_select_owner_or_doctor_or_admin"
on storage.objects for select
using (
  bucket_id = 'medical-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
    or exists (
      select 1 from public.appointments a
      where a.patient_id::text = (storage.foldername(name))[1]
        and a.doctor_id = auth.uid()
    )
  )
);

create policy "medical_documents_insert_owner_or_doctor"
on storage.objects for insert
with check (
  bucket_id = 'medical-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.current_role_is('doctor')
    or public.is_admin()
  )
);

create policy "medical_documents_delete_owner_or_admin"
on storage.objects for delete
using (
  bucket_id = 'medical-documents'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);
