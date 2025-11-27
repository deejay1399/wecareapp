-- Create reports table
create table public.reports (
  id uuid not null default gen_random_uuid (),
  reported_by uuid not null,
  reported_user uuid not null,
  reason character varying(100) not null,
  type character varying(50) not null,
  reference_id uuid not null,
  description text not null,
  status character varying(50) null default 'pending'::character varying,
  admin_notes text null,
  reporter_name character varying(255) null,
  reported_user_name character varying(255) null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint reports_pkey primary key (id)
) TABLESPACE pg_default;

-- Create indexes for better query performance
create index IF not exists idx_reports_status on public.reports using btree (status) TABLESPACE pg_default;

create index IF not exists idx_reports_type on public.reports using btree (type) TABLESPACE pg_default;

create index IF not exists idx_reports_reported_by on public.reports using btree (reported_by) TABLESPACE pg_default;

create index IF not exists idx_reports_reported_user on public.reports using btree (reported_user) TABLESPACE pg_default;

create index IF not exists idx_reports_reference_id on public.reports using btree (reference_id) TABLESPACE pg_default;

create index IF not exists idx_reports_created_at on public.reports using btree (created_at) TABLESPACE pg_default;

-- Enable RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Create simple permissive policies that allow all access
-- This allows the admin (with hardcoded login) to access reports
CREATE POLICY "Allow all access to reports"
  ON reports
  USING (true)
  WITH CHECK (true);
