# Authentication implementation

## Increment 1: student registration

The signup screen now calls Supabase Auth with email, password and display name.
It handles confirmation-required and immediate-session responses, returns to
sign-in for profile loading, and displays failures without claiming success.
The sign-in screen links to registration.

Before deploying this increment, apply
`supabase/migrations/20260930100000_safe_student_registration.sql` to a staging
database and verify its behavior. It replaces the metadata-controlled role
trigger with student-only creation and prevents email conflicts from reassigning
existing department profiles. Existing staff provisioning scripts must be reviewed
for compatibility; staff roles must be assigned by a trusted administrator.
The migration has not been applied to a remote database by this change.

Configure email confirmation, SMTP and the Site URL/redirect allowlist in Supabase.
Verify confirmation delivery with a test address. New registrations still need
administrator linkage to the official student roster; registration does not
prove student identity or grant access to an existing student's records.

Reference: https://supabase.com/docs/reference/dart/auth-signup

## Remaining increments

1. Require an active database profile and official student linkage at sign-in.
2. Restore sessions and respond to sign-out/token-expiry events in route guards.
3. Complete password recovery with a new-password screen and callback handling.
4. Validate role isolation and profile permissions using database integration tests.
5. Finish configuration/documentation cleanup and full regression checks.

## Increment 3: role access hardening

The migration `supabase/migrations/20260930110000_role_access_hardening.sql`
revokes client-side profile writes and narrows identity-table reads to the
authenticated user's profile, assigned advisor section, or HOD administration.
Apply it after the earlier hardening migrations and verify the policies in a
staging Supabase project with one test account for each role.

## Registration correction

For an existing official student roster, apply
`supabase/migrations/20260930105000_link_existing_student_profiles.sql` after
the registration migration. It resolves the unique-email conflict by linking a
new Auth user to the matching, unlinked STUDENT profile. It rejects HOD,
advisor, and already-linked profile conflicts.

## Student portal: read-only personal summary

Student and class-representative accounts now have the same personal dashboard:
their name, email, roll/register numbers, section, department, and attendance
percentage. Class rosters, leave history, attachment viewers, submission forms,
and pink-slip/leave/OD actions have been removed from this screen. Student login
no longer runs the staff-wide data synchronization.

The dashboard calls `get_my_student_dashboard()` with no student identifier.
The database resolves the official roster using `auth.uid()` and requires an
active STUDENT profile. It works with changed login emails because roster
membership uses `users.user_id = students.student_id`, not email or roll-number
metadata. No demo data or stored class roster is used as a fallback.

Attendance is `present recorded days / all recorded days * 100`, rounded to
one decimal place, excluding future dates in the college's Asia/Kolkata timezone.
It uses `daily_attendance.is_present` as the source of truth, without assigning
additional leave/OD credit. Missing records display “Not available”; unrecorded
days are not guessed as present or absent. No daily breakdown is sent to students.

### Deploy

1. After the earlier schema/security migrations, run
   `supabase/migrations/20260930120000_student_read_only_dashboard.sql` in the
   Supabase SQL Editor. This change has only been applied to a disposable local
   test database so far; it has not been applied to your hosted project.
2. Rebuild/restart Flutter and sign in with the linked student account. The
   dashboard requires the new RPC; before the migration it shows a retry message.
3. Confirm only the student's details and percentage appear. Try an advisor and
   HOD account to confirm their existing section/department workflows still work.

The migration adds restrictive policies so leftover permissive policies cannot
restore student access to attendance rows, leave slips, biometric events or leave
attachments. It retains existing staff permissions and restricts the legacy
account-provisioning RPC to `service_role` and database administrators, since
its definer privileges would otherwise allow clients to change account roles.
No roster, attendance, or leave records are deleted.

### Verification

- Targeted Flutter static analysis passes.
- 25 focused Flutter checks pass (personal dashboard, authentication regressions,
  existing dashboard regression, and responsive layouts).
- `supabase/tests/student_read_only_dashboard.sql` passes on PostgreSQL 18 with
  synthetic Auth/Storage schemas and the repository's base schema/RLS. It tests
  two students, inactive/unlinked accounts, empty attendance, future dates,
  denied direct reads/writes/RPC submissions, and advisor/HOD access.
- The SQL test creates fixtures and roles: run it **only in a fresh disposable
  local database**, never in the hosted project. Apply only the migration there.

Policy references: [PostgreSQL restrictive policies](https://www.postgresql.org/docs/16/sql-createpolicy.html)
and [Supabase database functions](https://supabase.com/docs/guides/database/functions).
