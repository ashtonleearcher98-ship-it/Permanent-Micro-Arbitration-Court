-- PMAC post-install verification (read-only)
-- Run in the Supabase SQL Editor after database/schema.sql.
-- All five tables should have RLS = true.
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('admin_users', 'membership_applications',
                    'case_submissions', 'published_cases', 'members')
order by tablename;

-- Intended anonymous privileges: INSERT for private submissions,
-- SELECT for public published cases and member directory,
-- nothing on admin_users.
select table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee = 'anon'
  and table_name in ('admin_users','membership_applications','case_submissions','published_cases','members')
order by table_name, privilege_type;

-- Inspect each policy before public launch.
select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in ('admin_users','membership_applications','case_submissions','published_cases','members')
order by tablename, policyname;
