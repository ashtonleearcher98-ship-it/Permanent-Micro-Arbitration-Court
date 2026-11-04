# PMAC — Permanent Micro-Arbitration Court Portal

A responsive, court-inspired website for the **proposed** Permanent Micro-Arbitration Court. Includes your uploaded seal, a modern public portal, membership and case submission forms, private Registry workspace, public case register, downloadable institutional drafts and a Supabase/Postgres database schema.

> **Institutional status:** PMAC is an independent proposed micronational initiative, not the Permanent Court of Arbitration (PCA). It is not a national court and does not claim compulsory jurisdiction or state enforcement powers. The site must not be marketed as a functioning arbitral institution until formally constituted and its Registry is ready.

## Included pages

| Route | Purpose |
| --- | --- |
| `#/` | Institutional homepage |
| `#/about` | Mission, scope and limits |
| `#/services` | Arbitration, mediation, conciliation |
| `#/cases` | Searchable published case register |
| `#/membership` | Membership rules and public directory |
| `#/join` | Private membership application |
| `#/submit-case` | Private case intake form |
| `#/governance` | Institutional structure and independence |
| `#/resources` | Draft conventions, procedure and ethics documents |
| `#/news` | Clearly marked institutional notices |
| `#/contact` | Contact pathways without invented details |
| `#/privacy` | Website privacy notice |
| `#/admin` | Password-protected authorised Registry workspace |

## Preview locally

From the project folder run:

```bash
python -m http.server 8080
```

Open `http://localhost:8080`. You can view all pages without a database. Submissions remain **disabled** until the dedicated database is configured; this prevents false success messages or accidental loss of enquiries.

## Create a dedicated Supabase database

1. Create a **new Supabase project specifically for PMAC**. Do **not** reuse another project's database or credentials.
2. Open **SQL Editor**, and execute `database/schema.sql`. The SQL creates five tables with row-level security and explicit grants:
   - `membership_applications` — private applicant records
   - `case_submissions` — private confidential intake requests
   - `published_cases` — independently authorised public case register
   - `members` — approved public member directory
   - `admin_users` — whitelist of authorised Registry accounts
3. Go to **Project Settings → API** and copy your project URL and **publishable** public key.
4. In `config.js`, set `supabaseUrl` and `supabasePublishableKey` to those two values. Your publishable key is designed for browser use, but it must be paired with secure RLS. **Never commit a service-role key, secret key or database password.**
5. In **Authentication → Users**, create an administrator user with an email/password. Use a strong password and enable MFA where practical.
6. Copy that user's Auth UUID, then in Supabase SQL Editor run this statement, replacing the UUID:

```sql
insert into public.admin_users(user_id)
values ('REPLACE-WITH-THE-REAL-AUTH-USER-UUID');
```

7. Test `#/admin` using that account, and test both public forms. A successful submission gets a unique reference code. Submissions can be read only by authorised admins. The case register **does not publish** private intake automatically.
8. Approved members can be added to the public directory from SQL Editor. For example:

```sql
insert into public.members (name,website,admitted_on,status,is_public)
values ('Example Micronation','https://example.org',current_date,'active',true);
```

Only publish real, authorised members and cases. The example SQL above is illustrative; don't execute it with fictional member data for a live directory.

### Security notes before public intake

**This is a deployment-ready starter, not a fully hardened legal case-management service.** Anonymous visitors are permitted to INSERT initial enquiries into two private tables, with no public SELECT permission. Production public intake needs an anti-spam/rate-limited server-side endpoint (such as Supabase Edge Functions with CAPTCHA), verified contact addresses, an audit trail, a retention schedule, incident response rules and a legal privacy review. Otherwise attackers may flood the database, even though they cannot read others' filings.

Store sensitive case evidence only in a later dedicated secure evidence system. The form expressly does not accept attachments or highly sensitive evidence.

### Why separate public and private tables?

- Private `case_submissions` hold personal contact and dispute details and have no anonymous read grant.
- `published_cases` is a separate table. Only whitelisted Registry administrators can write to it, and visitors can read only `is_public = true` rows.
- `members` is a separate approved directory, so an application is never automatically a public member.
- The web interface does **not** rely on a hidden `/admin` URL for security. All authority is verified by Postgres RLS.

## Create a new PUBLIC GitHub repository

GitHub is connected for file operations, but repository creation and GitHub Pages activation might need your action in GitHub itself.

1. At [github.com/new](https://github.com/new), enter repository name `permanent-micro-arbitration-court` and choose **Public**.
2. If you want me to upload the code through the connected GitHub app in a follow-up, tick **Add a README file** when creating the repository so it already has a `main` branch. If you are uploading the ZIP contents manually, an empty repository also works.
3. Upload the contents of this directory **at the repository root**, including the hidden `.github` folder and `.nojekyll` file (not only the ZIP file). Replace the starter README with this project README if you chose to initialise one.
4. Open your repository → **Settings → Pages → Build and deployment** → set **Source: GitHub Actions**.
5. Commit to `main`. The included `.github/workflows/deploy.yml` will deploy the site.
6. The expected website address will be of the form `https://YOUR-USERNAME.github.io/permanent-micro-arbitration-court/`. Confirm the exact URL in the repository's Pages settings; do not assume it is live until deployment succeeds.

All internal routes use hash URLs (`#/cases`, `#/join`, etc.) so they work under GitHub Pages project subpaths without a server rewrite.

## Project structure

```
index.html                    Main HTML structure and navigation
styles.css                    Full responsive visual design
app.js                        Routing, forms, admin, public registry
config.js                     Public-only database configuration
assets/pmac-seal.webp          Supplied official seal (cropped and optimised)
assets/favicon.svg            Compact PMAC site icon
database/schema.sql           Supabase tables, grants and RLS policies
documents/*.md                Proposed institutional drafts
.github/workflows/deploy.yml  GitHub Pages deployment workflow
.nojekyll                     Prevent unwanted Jekyll processing
```

## Manual acceptance testing

- Navigate every menu item and verify page titles and mobile menu behavior.
- Submit an incomplete form and verify HTML validation blocks it.
- Without configuration, verify both submit buttons are disabled and a clear setup note appears.
- With configuration, submit one test application and case and verify both appear under authorised `/admin` only.
- Verify a signed-out client cannot query `membership_applications` or `case_submissions`.
- Verify new private cases are not present in `published_cases`.
- Sign in as an unauthorised Auth user and verify `/admin` denies access.
- Publish and unpublish one approved test record using the Registry workspace; remove test content afterward.
- Check display at 360px, 768px and 1440px viewports.

© 2026 PMAC founding initiative. No association with the Permanent Court of Arbitration in The Hague.
