# PMAC database activation

The website already includes joining, private preliminary case filings, an approved-only public case register and a restricted Registry dashboard. It needs a dedicated Supabase project. **Do not use the database of an unrelated project.**

## 1. Create and initialise Supabase

1. Create a dedicated project at https://supabase.com/dashboard.
2. In **SQL Editor**, run `database/schema.sql` from this repository. Read the whole script before executing it.
3. Confirm tables exist: `membership_applications`, `case_submissions`, `published_cases`, `members`, `admin_users`. Each should have row-level security enabled.
4. In **Project Settings → API Keys**, copy your project URL and **publishable** key (`sb_publishable_...`), not a secret key, legacy service_role key, or database password.

## 2. Link GitHub Pages without editing the code

In GitHub repository **Settings → Secrets and variables → Actions → Variables → New repository variable**, create:

| Name | Value |
| --- | --- |
| `PMAC_SUPABASE_URL` | `https://YOUR-PROJECT.supabase.co` |
| `PMAC_SUPABASE_PUBLISHABLE_KEY` | the project's public `sb_publishable_...` key |

Both are **public client configuration**, so do not use the elevated `sb_secret_...` or service-role key. The GitHub Pages workflow generates the production `config.js` at deploy time using these variables.

Next, go to **Actions → Deploy PMAC website to GitHub Pages → Run workflow**. Once deployed, check that the **Join PMAC** and **Submit a case** forms are no longer disabled. With no variables, the site remains read-only by design.

## 3. Add a Registry administrator

The Registry login uses Supabase Auth. In Supabase Dashboard → Authentication → Users, create an authorised admin with a strong password and verified email. Copy its `auth.users.id` UUID.

In Supabase SQL Editor run (replace the UUID only in the editor):

```sql
insert into public.admin_users (user_id)
values ('00000000-0000-0000-0000-000000000000')
on conflict (user_id) do nothing;
```

Never commit passwords or service-role keys to GitHub. Admin access is controlled by the `admin_users` table plus row-level security, not by hiding a page.

## 4. Test the complete lifecycle

- Submit a test micronation application through `#/join`. On success, the website must display an application reference.
- Submit a fictional test case through `#/submit-case`. On success, the website must display a different reference.
- Verify both rows in Supabase; use fictitious data only.
- Sign in through `#/admin`; confirm the two records are visible to the authorised administrator.
- Change application and case intake statuses. These are **review statuses**, not automatically accepted memberships or jurisdiction.
- Use **Publish a case** to create a deliberately approved, fictitious public record. Check that only this public record appears in `#/cases`.
- Verify an unauthenticated visitor **cannot** read `membership_applications` or `case_submissions`. Do not run tests using real people's confidential case facts.

## Important data-security limitations

This initial release permits anonymous INSERT-only requests to private intake tables. Public read/update/delete access is blocked through PostgreSQL grants and RLS, and public records must be deliberately published by a Registry administrator. Nevertheless, the anonymous intake endpoints could be abused with spam. Before wider public use, implement rate limiting, CAPTCHA/Turnstile verification, complaint and deletion procedures, encrypted backups, admin multi-factor authentication, and an incident response plan. Avoid asking submitters for identity documents or highly sensitive evidence.

**Status:** Adding variables alone is insufficient; SQL must be run in the *same* dedicated Supabase project. Database setup must be confirmed with an actual end-to-end test before calling the forms live.
