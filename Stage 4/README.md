# Smart Medication Management System #

## Stage 4: MVP Development and Execution ##

Team Members:

Rama · Raghad · Jana · Amaal


 

# 0\. Sprint Plan

Development for the Dawai MVP was organized into two sprints of two weeks each, following Scrum practices. Tasks were prioritized using the MoSCoW framework (Must have, Should have, Could have, Won't have) and assigned based on team members' focus areas.

## Roles

| Role | Owner | Responsibilities |
| ----- | ----- | ----- |
| Project Manager (PM) | Raghad | Sprint planning, progress tracking, deadline coordination |
| Source Control Manager (SCM) | Rama | Git branching strategy, pull request reviews, merge integrity |
| Quality Assurance (QA) | Raghad | Test plans, manual/unit/integration testing, bug verification |
| Backend Developers | Rama \- Raghad | API routes, database schema/migrations, authentication |
| Frontend Developers | Raghad · Amaal · Jana | Flutter UI screens, state management, API integration |

## Sprint 1 (Weeks 1–2): Core Foundations

Goal: establish authentication, the caregiver-dependent data model, and basic medication CRUD so the app has a working, securable backbone.

| Task | Priority | Owner | Status |
| ----- | ----- | ----- | ----- |
| Design PostgreSQL schema & migrations (users, medications, schedules, dose\_records) | Must | Rama | Done |
| Implement email/password | Must | Rama | Done |
| Implement JWT auth middleware across protected routes | Must | Raghad | Done |
| Build dependents table \+ caregiver-dependent relationship | Must | Raghad | Done |
| Flutter: onboarding, login, and home screen shell | Must | Amaal | Done |
| Flutter: dependent switcher (profile menu, selected-dependent state) | Should | Jana | Done |
| Medication CRUD (create/read/update/delete) API \+ UI | Must | Rama / Raghad | Done |

## Sprint 2 (Weeks 3–4): Medicine Catalog, Adherence & Hardening

Goal: connect the app to a real medicine catalog for search-assisted entry, add dose-taken tracking (adherence), and close security gaps found during Sprint 1 review.

| Task | Priority | Owner | Status |
| ----- | ----- | ----- | ----- |
| Seed medicines reference catalog (\~3,758 entries, EN/AR) into PostgreSQL | Must | Rama \- Raghad | Done |
| Build GET /medicines/search endpoint | Must | Rama | Done |
| Flutter: live medicine search \+ autocomplete in Add-Medication sheet | Must | Rama \- Raghad | Done |
| Enforce dependent-ownership checks on /medications endpoints | Must | Raghad | Done |
| Fix missing auth middleware on /medications router (security bug) | Must | Rama \- Raghad | Done |
| Dose adherence tracking (POST/PATCH/GET /dose-logs, GET /adherence/rate) | Should | Rama / Jana | Done |
| Dedicated adherence-tracking screen in Flutter | Should | Jana | Done |
| Responsive date-strip UI polish | Could | Amaal – Rama \- Raghad | Done |
| Debounce medicine-search input for performance | Could | Raghad \- Rama | Done |
| Push notifications for reminders | Must | Amaal | Done |

# 1\. Execute Development Tasks

## Backend

The backend is built with Node.js and the Hono framework, backed by PostgreSQL. Key implementation points:

●      JWT-based authentication with bcrypt password hashing

●      A middleware layer (authMiddleware) validates the bearer token and attaches the user object to the request context for every protected route.

●      The medications table carries a nullable dependent\_id column: NULL means the record belongs to the caregiver; a value ties it to a specific dependent.

●      Ownership is enforced in the route handlers before each read or write, the caregiver's id is checked against dependents.caregiver\_user\_id for the medication's linked dependent.

●      A medicines reference table (distinct from medications) was seeded from a cleaned pharmaceutical dataset, providing English/Arabic names, dosage, category, description, and warnings for \~3,758 items.

●      Dose adherence is tracked via a dose\_records table, exposed through dose-logs (create/list/update) and summarized through /adherence/rate.

## Frontend

The frontend is built with Flutter, using the Provider package for state management.

●      DependentProvider holds the currently selected dependent (or null for the caregiver's own profile) and drives which API endpoint the home screen calls.

●      The home screen's top bar exposes a profile.

●      The home screen's bottom bar has a navigation bar to (my medicines – reminder – my account) in my account there is a menu (account info, my medications, adherence tracking, dependents, appearance, language, sign out).

●      The Add-Medication sheet includes a live search field against the medicines catalog, auto-filling name and dosage when a suggestion is selected.

●      Dose check-off in the Reminders tab syncs with the backend dose-logs endpoints, with a local SharedPreferences fallback when the user is not authenticated.

●      A dedicated Adherence screen shows the overall adherence rate and a chronological dose log, reusing the medications list already loaded for the active profile (caregiver or dependent).

## Version Control

The team used Git with feature branches per task, merged into the development branch after review. \[SCM to insert: branching model diagram / PR review process summary specific to this repository.\]

# 2\. Monitor Progress and Adjust

## Metrics

| Metric | Sprint 1 | Sprint 2 |
| ----- | ----- | ----- |
| Planned tasks | 7 | 10 |
| Completed tasks | 7 | 10 |
| Sprint velocity (tasks/sprint) | 7 | 10 |
| Critical bugs found | 2 | 2 |
| Critical bugs resolved | 2 | 2 |

## Deviations & Adjustments

●      Local PostgreSQL setup (missing installation, misconfigured DATABASE\_URL port) delayed running migrations; resolved by installing PostgreSQL and correcting the connection string.

●      A migration file (007, unrelated "better-auth" tables) failed and was skipped since it was not wired into the actual authentication flow (auth/offline.js), unblocking the remaining migrations (008–010).

●      The authMiddleware was found to be imported but never applied on the /medications router, causing 500 errors and, more importantly, leaving the endpoint unauthenticated; this was corrected mid-sprint and re-tested.

●      A missing ownership check allowed any authenticated user to update any dose record by ID; a user\_id verification step was added before writing dose-record data.

# 3\. Sprint Reviews and Retrospectives

## Sprint 1 Review

Demoed: account creation/login via email, switching between the caregiver's own profile and a dependent's profile, and adding/editing/deleting a medication for either.

## Sprint 1 Retrospective

●      What worked well: clear split between backend (Rama) and Flutter screens (Raghad/Amaal/Jana) avoided merge conflicts.

●      Challenges: the pool.js in-memory fallback masked database connection issues, making some bugs look like application logic errors.

●      Improvement for next sprint: add a visible connection-status check on backend startup so a failed DB connection is obvious immediately.

## Sprint 2 Review

Demoed: live medicine search while adding a medication, dose check-off syncing to the backend, and the new adherence-tracking screen showing completion rate and dose history.

## Sprint 2 Retrospective

●      What worked well: reusing the existing dose-logs/adherence backend routes (built earlier but unused) saved significant time.

●      Challenges: manual file-by-file patching across team member caused occasional merge drift (duplicate code, mismatched function names); but a stricter PR-review step caught this earlier.

●      Improvement for next sprint: enforce full-file review on pull requests touching shared screens (e.g., home\_screen.dart) rather than patching in isolation.

# 4\. Final Integration and QA Testing

Manual QA review should be requested once the checklist below is verified end-to-end.

## Manual QA Checklist

●      Sign up / log in via email and confirm token persistence across app restarts.

●      Add a dependent (name, age, relationship) and confirm it appears only under the caregiver who created it.

●      Add a medication for the caregiver's own profile confirm it does not appear under any dependent.

●      Add a medication for a dependent confirm it does not appear on the caregiver's own medication list.

●      Search the medicine catalog and confirm both English and Arabic names return relevant results.

●      Mark a dose as taken, restart the app, and confirm the checkbox state persists (synced from the backend).

●      Open the adherence screen and confirm the percentage matches the ratio of taken to total logged doses.

●      Attempt to access another caregiver's dependent by ID directly via the API and confirm a 403 response.

●      Sign out and confirm protected screens are no longer reachable without logging back in.

●      Push notification reminders are tested before merge.

 

## Known Issues / Backlog

●      Medicine search fires a request on every keystroke; a debounce delay is planned but not yet merged.

# 5\. Deliverables

Links to be completed by the team before submission:

●      Sprint Reviews: \[Insert link — e.g., recorded demo or meeting notes\]

●      Retrospectives: \[Insert link — e.g., Trello/Notion board\]

●      Sprint Planning: \[Insert link — e.g., Trello board with Sprint 1 / Sprint 2 columns\]

●      Source repository: \[https://github.com/janabakri/Portfolio\_Project\]

●      Bug tracking: \[https://github.com/janabakri/Portfolio\_Project/issues\]

●      Testing evidence and results: \[<img width="960" height="540" alt="Screenshot 2026-07-26 105203" src="https://github.com/user-attachments/assets/d92c8b60-9028-4c1d-aae7-601c33fd8382" />
 ]
   
    PS C:\Users\nayya\Portfolio_Project\backend> npm test            

    > portfolio-project-backend@1.0.0 test
    > npm run migrate:reset && jest --runInBand


    > portfolio-project-backend@1.0.0 migrate:reset
    > node scripts/runSqlMigrations.js --reset

    Connected to database. Running SQL migrations...
    Resetting public schema...
    Applying migration: 001_create_enums.sql
    Applying migration: 002_create_tables.sql
    Applying migration: 003_create_indexes.sql
    Applying migration: 004_create_triggers.sql
    Applying migration: 005_seed_medicines.sql
    Applying migration: 006_seed_drug_interactions.sql
    Applying migration: 007_update_user_type_enum.sql
    Applying migration: 008_create_dependents_table.sql
    Applying migration: 009_add_dependent_to_medications.sql
    Applying migration: 010_add_medication_schedule_fields.sql
    SQL migrations completed successfully.
    PASS  tests/auth.test.js
    ● Console

    console.log
      JWT_SECRET = test-secret

      at Object.log (src/server.js:2:9)

    console.log
       DATABASE_URL exists: true

      at Object.log (src/db/pool.js:5:9)

    console.log
       DATABASE_URL starts with: postgresql://postgres:12345ra@

      at Object.log (src/db/pool.js:6:9)

    PASS  tests/interactions.test.js
    ● Console

    console.log
      JWT_SECRET = test-secret

      at Object.log (src/server.js:2:9)

    console.log
       DATABASE_URL exists: true

      at Object.log (src/db/pool.js:5:9)

    console.log
       DATABASE_URL starts with: postgresql://postgres:12345ra@

      at Object.log (src/db/pool.js:6:9)

    PASS  tests/offlineAuth.test.js
    ● Console

    console.log
      JWT_SECRET = test-secret

      at Object.log (src/server.js:2:9)

    console.log
       DATABASE_URL exists: true

      at Object.log (src/db/pool.js:5:9)

    console.log
       DATABASE_URL starts with: postgresql://postgres:12345ra@

      at Object.log (src/db/pool.js:6:9)


    Test Suites: 3 passed, 3 total
    Tests:       9 passed, 9 total
    Snapshots:   0 total
    Time:        2.301 s, estimated 3 s
    Ran all test suites.

●      Production environment: \[http://localhost:56417/\][<img width="1600" height="900" alt="QR code APK " src="https://github.com/user-attachments/assets/4268c0dc-cecb-4c86-910f-60df27f13053" />]

