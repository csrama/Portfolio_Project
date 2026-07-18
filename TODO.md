# TODO - End-to-End Authentication + Home Page

## Completed
- [x] Frontend AuthService: added login/register/logout helpers and fixed token getter return type.
- [x] Backend auth endpoints: `/auth/register` and `/auth/login` now return `refreshToken`.
- [x] Backend auth endpoints: added `/auth/refresh` and `/auth/logout`.
- [x] Backend tests updated for refresh flow.

## Still required (DB-backed invalidation)
- [ ] Replace in-memory `refreshTokensStore` with Postgres-backed storage.
  - Use existing tables in `backend/src/db/migrations/007_better_auth_tables.sql` (session/account) OR add a new migration.
- [ ] Update `backend/src/db/pool.js` with queries for refresh token/session revocation.
- [ ] Update backend `/auth/refresh` and `/auth/logout` to use DB.
- [ ] Ensure `/auth/google` and offline auth flows also return `refreshToken` (or adapt frontend).

## Testing
- [ ] Fix inability to run npm/flutter tests under current shell restrictions (avoid && / || separators).
- [ ] Run backend tests + frontend tests and ensure compilation passes.

## Home page end-to-end
- [ ] Verify logout redirects to onboarding/splash and home page no longer uses API calls after logout.

