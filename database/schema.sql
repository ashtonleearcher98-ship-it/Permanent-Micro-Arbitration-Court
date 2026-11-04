-- PMAC — Dedicated Supabase schema, version 1.0
-- Run ONCE in a new, dedicated Supabase project. No private credentials belong in GitHub.
-- RLS is enabled for every exposed table; grants are explicitly limited.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique check (length(reference_code) between 10 and 45),
  entity_name varchar(130) not null check (length(trim(entity_name)) >= 3),
  founded_year integer check (founded_year between 1800 and 2100),
  website varchar(250),
  representative varchar(130) not null,
  representative_title varchar(130) not null,
  contact_email varchar(250) not null,
  region varchar(130),
  description text not null check (length(description) between 25 and 2500),
  charter_acknowledged boolean not null default false check (charter_acknowledged),
  authority_confirmed boolean not null default false check (authority_confirmed),
  privacy_acknowledged boolean not null default false check (privacy_acknowledged),
  status text not null default 'received' check (status in ('received','under_review','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.case_submissions (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique check (length(reference_code) between 10 and 45),
  title varchar(180) not null check (length(trim(title)) >= 5),
  category text not null check (category in ('diplomatic','treaty','constitutional','electoral','organisational','territorial','other')),
  requested_process text not null check (requested_process in ('arbitration','mediation','conciliation','unsure')),
  claimant varchar(180) not null,
  respondent varchar(180) not null,
  filer_name varchar(140) not null,
  filer_role varchar(140) not null,
  contact_email varchar(250) not null,
  consent_status text not null check (consent_status in ('both','claimant_only','not_yet')),
  summary text not null check (length(summary) between 50 and 7000),
  relief_requested text not null check (length(relief_requested) between 15 and 3000),
  authority_confirmed boolean not null default false check (authority_confirmed),
  accept_limitations boolean not null default false check (accept_limitations),
  privacy_acknowledged boolean not null default false check (privacy_acknowledged),
  status text not null default 'received' check (status in ('received','under_review','accepted','closed','rejected')),
  created_at timestamptz not null default now()
);

-- Publicly approved records are NEVER taken automatically from private filings.
create table if not exists public.published_cases (
  id uuid primary key default gen_random_uuid(),
  case_number varchar(40) not null unique,
  title varchar(180) not null,
  category text not null check (category in ('diplomatic','treaty','constitutional','electoral','organisational','territorial','other')),
  claimant varchar(180) not null,
  respondent varchar(180) not null,
  status text not null check (status in ('pending','active','closed')),
  summary varchar(2000) not null default '',
  is_public boolean not null default false,
  published_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null unique,
  website varchar(250),
  admitted_on date,
  status text not null default 'active' check (status in ('active','suspended','withdrawn')),
  is_public boolean not null default false
);

alter table public.admin_users enable row level security;
alter table public.membership_applications enable row level security;
alter table public.case_submissions enable row level security;
alter table public.published_cases enable row level security;
alter table public.members enable row level security;

-- Explicitly revoke the broad grants Supabase may provide by default.
revoke all on public.admin_users from public, anon, authenticated;
revoke all on public.membership_applications from public, anon, authenticated;
revoke all on public.case_submissions from public, anon, authenticated;
revoke all on public.published_cases from public, anon, authenticated;
revoke all on public.members from public, anon, authenticated;

-- Check admin membership from a SECURITY DEFINER routine to avoid recursive RLS.
create or replace function public.is_pmac_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_pmac_admin() from public, anon;
grant execute on function public.is_pmac_admin() to authenticated;

-- Admin accounts only see their OWN role row. No public role listing.
create policy "Administrators can verify their own role" on public.admin_users
  for select to authenticated using (user_id = (select auth.uid()));
grant select on public.admin_users to authenticated;

-- Public may submit, but cannot read, list, edit or remove private filings.
create policy "Anyone may lodge a preliminary application" on public.membership_applications
  for insert to anon, authenticated with check (
    status = 'received' and charter_acknowledged and authority_confirmed and privacy_acknowledged
  );
create policy "Authorised staff read applications" on public.membership_applications
  for select to authenticated using (public.is_pmac_admin());
create policy "Authorised staff update application status" on public.membership_applications
  for update to authenticated using (public.is_pmac_admin()) with check (public.is_pmac_admin());
grant insert on public.membership_applications to anon, authenticated;
grant select, update on public.membership_applications to authenticated;

create policy "Anyone may lodge a preliminary case request" on public.case_submissions
  for insert to anon, authenticated with check (
    status = 'received' and authority_confirmed and accept_limitations and privacy_acknowledged
  );
create policy "Authorised staff read case requests" on public.case_submissions
  for select to authenticated using (public.is_pmac_admin());
create policy "Authorised staff update case status" on public.case_submissions
  for update to authenticated using (public.is_pmac_admin()) with check (public.is_pmac_admin());
grant insert on public.case_submissions to anon, authenticated;
grant select, update on public.case_submissions to authenticated;

-- Public can view ONLY expressly published case entries. Staff can manage.
create policy "Anonymous visitors read public cases" on public.published_cases
  for select to anon using (is_public);
create policy "Authenticated users read public or authorised cases" on public.published_cases
  for select to authenticated using (is_public or (select public.is_pmac_admin()));
create policy "Authorised staff publish cases" on public.published_cases
  for insert to authenticated with check (public.is_pmac_admin());
create policy "Authorised staff manage public cases" on public.published_cases
  for update to authenticated using (public.is_pmac_admin()) with check (public.is_pmac_admin());
grant select on public.published_cases to anon, authenticated;
grant insert, update on public.published_cases to authenticated;

create policy "Anonymous visitors read active public members" on public.members
  for select to anon using (is_public and status = 'active');
create policy "Authenticated users read public or authorised members" on public.members
  for select to authenticated using ((is_public and status = 'active') or (select public.is_pmac_admin()));
create policy "Authorised staff add members" on public.members
  for insert to authenticated with check (public.is_pmac_admin());
create policy "Authorised staff manage members" on public.members
  for update to authenticated using (public.is_pmac_admin()) with check (public.is_pmac_admin());
grant select on public.members to anon, authenticated;
grant insert, update on public.members to authenticated;

-- IMPORTANT: populate admin_users only after creating a trusted Supabase Auth account.
-- Example — run only in SQL Editor, replacing the placeholder with the real auth.users UUID:
-- insert into public.admin_users(user_id) values ('00000000-0000-0000-0000-000000000000');
-- Do not place admin user IDs in your public repository if they identify a private individual.

-- Production hardening: add a rate-limited server-side intake endpoint with CAPTCHA,
-- email verification, abuse detection, retention rules and an audit-log process.
-- Public direct inserts are enabled for initial low-volume setup; they are NOT abuse-proof.
