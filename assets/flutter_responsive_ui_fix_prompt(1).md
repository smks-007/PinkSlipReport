# Flutter Application — Complete Dynamic Responsive UI Fix

## ROLE

Act as a senior Flutter UI/UX engineer specializing in responsive mobile application development.

Analyze the **entire existing Flutter project** and refactor only the UI/layout layer so that the application works correctly on **all common mobile screen sizes and resolutions**, especially compact devices.

The application must remain visually consistent with the current design while becoming fully responsive.

---

# 1. PRIMARY OBJECTIVE

Fix **ALL UI responsiveness and overflow problems** throughout the Flutter application.

The application must work correctly in portrait mode on:

- 320 × 568
- 360 × 640
- 375 × 667
- 390 × 844
- 412 × 915
- 430 × 932

Do NOT design specifically for only these resolutions.

The implementation must dynamically adapt to **any reasonable mobile screen size**.

The UI must never:

- Overflow horizontally
- Overflow vertically
- Clip important content
- Push buttons outside the screen
- Hide text unexpectedly
- Cause `RenderFlex overflowed` errors
- Create unusable dialogs
- Break when the keyboard opens
- Break when system font size is increased

---

# 2. CRITICAL NON-REGRESSION RULE

DO NOT MODIFY application business logic.

Do NOT modify:

- Supabase configuration
- Database schema
- Database queries
- Authentication logic
- Authorization
- JWT/session handling
- API calls
- Models
- Providers
- Services
- Repositories
- Controllers
- State-management logic
- Attendance calculations
- Pink-slip workflow
- Approval workflow
- Navigation logic unless required only for UI presentation
- Mock-data logic
- Existing functionality

Only modify the UI/layout implementation where necessary.

The application must behave exactly as it currently does after the responsive refactor.

---

# 3. VISUAL DESIGN MUST REMAIN CONSISTENT

Do NOT redesign the application.

Preserve the existing:

- Colors
- Gradients
- Typography
- Font sizes where practical
- Icons
- Logos
- Branding
- Cards
- Borders
- Shadows
- Buttons
- Backgrounds
- Visual hierarchy
- Existing animations

The goal is:

> SAME DESIGN + RESPONSIVE LAYOUT

Do not unnecessarily change the application's appearance.

---

# 4. FIRST — ANALYZE THE ENTIRE PROJECT

Before editing files:

1. Scan the complete Flutter project.
2. Identify every screen.
3. Identify every dialog.
4. Identify every bottom sheet.
5. Identify every reusable widget.
6. Search for hardcoded dimensions.
7. Search for rigid `Row` layouts.
8. Search for fixed-width widgets.
9. Search for fixed-height widgets.
10. Search for `Spacer()` usage inside constrained layouts.
11. Search for long text inside `Row`.
12. Search for dialogs with fixed `maxHeight`.
13. Search for horizontal button groups.
14. Search for `MediaQuery` usage.
15. Search for existing responsive utilities.

Create a mental map of all potentially problematic layouts before making changes.

---

# 5. RESPONSIVE DESIGN SYSTEM

Use Flutter's native responsive layout primitives.

Prefer:

```dart
LayoutBuilder
MediaQuery.sizeOf(context)
Expanded
Flexible
Wrap
ConstrainedBox
FractionallySizedBox
SafeArea
SingleChildScrollView
CustomScrollView
SliverList
SliverGrid
```

Do NOT solve responsiveness by simply reducing font sizes everywhere.

Do NOT randomly add `SizedBox` values until overflow disappears.

Do NOT use arbitrary hardcoded widths to solve responsive problems.

---

# 6. RESPONSIVE BREAKPOINTS

Use width-based breakpoints rather than device-specific code.

Recommended:

```text
< 360px
```

Compact layout.

```text
360px - 399px
```

Normal compact layout.

```text
400px+
```

Large mobile layout.

These breakpoints are guidelines only.

The layout must continue to work between and beyond these values.

---

# 7. FIX RIGID ROWS

Search the project for layouts similar to:

```dart
Row(
  children: [
    WidgetA(),
    WidgetB(),
    WidgetC(),
  ],
)
```

Determine whether the children can overflow.

Where appropriate, use:

```dart
Expanded(
  child: ...
)
```

or:

```dart
Flexible(
  child: ...
)
```

For action buttons that legitimately need to move onto another line:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ...
  ],
)
```

Do NOT blindly convert every `Row` to `Wrap`.

Choose the layout based on the intended UI.

---

# 8. TEXT RESPONSIVENESS

Every text element inside a constrained horizontal layout must be checked.

Use:

```dart
Flexible(
  child: Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
)
```

or:

```dart
Expanded(
  child: Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
)
```

when appropriate.

The UI must handle:

- Long student names
- Long course names
- Long department names
- Long status labels
- Long button labels
- Long headings
- Increased system font size

Never allow important text to push other widgets outside the screen.

---

# 9. HOD DASHBOARD

Fix the following areas.

## Executive Statistics

If four statistics currently appear in one rigid row, make the layout responsive.

For compact screens:

```text
┌──────────────┬──────────────┐
│ Total        │ Present      │
├──────────────┼──────────────┤
│ Absentees    │ Pending      │
└──────────────┴──────────────┘
```

For wider screens, the statistics may remain in a single row if they fit naturally.

Use `LayoutBuilder` or width-based responsive logic.

## Navigation Tabs

The following tabs must never overflow:

- Overview
- Sections
- Approvals
- Promotion

Adapt spacing and text presentation for narrow screens.

Do not allow tabs to extend beyond the viewport.

## Pink Slip Approval Cards

The following actions must remain accessible:

- View Voucher
- Reject
- Sign & Approve

On narrow screens, allow buttons to wrap onto multiple lines.

Never allow buttons to leave the screen.

## Header / Badge Row

Handle:

- Student name
- Status
- Date
- OD/pass badges

Use `Flexible`, `Expanded`, or `Wrap` appropriately.

---

# 10. CLASS ADVISOR DASHBOARD

Fix:

## App Bar

The following must remain responsive:

```text
SMART PRO
Dept of AI & DS • Class Advisor Portal
```

Use `Expanded` where necessary.

## Pink Slip Actions

These actions:

- View Voucher
- Reject
- Endorse & Forward

must wrap gracefully on compact screens.

## Attendance Statistics

Make all statistic cards flexible.

Long text must not cause overflow.

---

# 11. STUDENT DASHBOARD

Fix the profile statistics:

- Class Strength
- Present Today
- Absentees

Do not rely on `MainAxisAlignment.spaceAround` alone.

Use `Expanded` and `Flexible` so each item receives an appropriate amount of space.

Also ensure the **Submit Leave / Pink Slip bottom sheet** responds correctly when the keyboard appears.

Use:

```dart
MediaQuery.viewInsetsOf(context)
```

where appropriate.

---

# 12. SIGN-IN SCREEN

Find fixed dimensions such as:

```dart
height: 290
```

Do not simply preserve a fixed height.

Make the header responsive using available screen height.

For example:

```dart
final height = MediaQuery.sizeOf(context).height;

final headerHeight = height.clamp(
  180.0,
  290.0,
);
```

Adjust this based on the existing design.

Cloud/background decorative elements must also remain inside the visible area.

Connection/security status rows must handle narrow widths.

---

# 13. FORGOT PASSWORD SCREEN

Remove rigid spacing such as:

```dart
SizedBox(width: 44)
```

when it causes the header to overflow.

The title:

```text
FACULTY CREDENTIAL RECOVERY
```

must fit naturally on compact screens.

Use `Flexible`, `Expanded`, `maxLines`, and `TextOverflow.ellipsis` where appropriate.

---

# 14. SECURITY VERIFICATION SCREEN

Ensure:

- PIN keypad
- Biometric controls
- Verification buttons
- Headers

remain visible on short devices.

The layout must not depend on a fixed vertical height.

Use scrolling only when necessary.

Do not hide critical controls.

---

# 15. TIMETABLE SCREEN

Long subjects must not push badges or other information offscreen.

For example:

```text
Artificial Intelligence and Machine Learning Laboratory
```

must be handled safely.

Use `Flexible`, `Expanded`, `maxLines`, and `TextOverflow.ellipsis` for constrained subject titles.

If section/room chips cannot fit, allow them to scroll or wrap naturally.

---

# 16. ATTENDANCE REPORT DIALOG

If four metrics currently appear in one row:

- Attendance
- Present
- Absent Today
- On-Duty

make them responsive.

On narrow screens use a 2×2 layout:

```text
┌──────────────┬──────────────┐
│ Attendance   │ Present      │
├──────────────┼──────────────┤
│ Absent       │ On-Duty      │
└──────────────┴──────────────┘
```

On larger screens they may remain in one row.

---

# 17. CREATE PINK SLIP DIALOG

Never use a fixed dialog height such as:

```dart
maxHeight: 780
```

Calculate available height dynamically.

Use something similar to:

```dart
final screenHeight = MediaQuery.sizeOf(context).height;

final maxDialogHeight = screenHeight * 0.9;
```

The dialog body must be scrollable.

The dialog must remain usable when:

- Screen is 568px high
- Keyboard is visible
- Keyboard occupies a large portion of the screen
- Font size is increased

Important fields and submit buttons must remain accessible.

---

# 18. AI / JARVIS COMPONENTS

Check:

- JARVIS FAB
- Role AI Agent Sheet

Long titles and badges must not overflow.

Use `Flexible`, `Expanded`, `Wrap`, and `TextOverflow.ellipsis` where appropriate.

Bottom sheets must respect safe areas and keyboard insets.

---

# 19. SAFE AREA

Review all screens for:

```dart
SafeArea
```

Ensure content does not collide with:

- Status bar
- Navigation bar
- Camera/notch areas
- Gesture areas

Do not add unnecessary padding if SafeArea already handles it.

---

# 20. KEYBOARD RESPONSIVENESS

Test all forms with the keyboard open.

The following must remain usable:

- Login
- Forgot Password
- Security verification
- Pink Slip creation
- Leave reason input
- Any text fields
- AI/chat input

Use:

```dart
MediaQuery.viewInsetsOf(context)
```

and scrolling where appropriate.

The keyboard must never cover the primary action button.

---

# 21. REMOVE DANGEROUS FIXED DIMENSIONS

Search for:

```text
width:
height:
SizedBox(
Container(
ConstrainedBox(
```

and identify dimensions that are unnecessarily fixed.

Do NOT remove all fixed dimensions.

Fixed dimensions are acceptable for:

- Icons
- Small visual elements
- Borders
- Standard button heights
- Decorative elements

They are dangerous when used for large content containers.

---

# 22. DO NOT USE THESE AS QUICK FIXES

Do NOT:

- Reduce everything to tiny fonts
- Hide widgets
- Delete buttons
- Delete information
- Use horizontal scrolling for the entire screen
- Use random fixed widths
- Use random negative margins
- Disable overflow warnings
- Wrap the entire app in `SingleChildScrollView`

These are not real responsive solutions.

---

# 23. AUTOMATED RESPONSIVE TESTING

Create:

```text
test/responsive_ui_test.dart
```

Test important screens at:

- 320 × 568
- 360 × 640
- 375 × 667
- 390 × 844
- 412 × 915
- 430 × 932

At minimum test:

- SignInScreen
- ForgotPasswordScreen
- SecurityVerificationScreen
- HOD Dashboard
- Advisor Dashboard
- Student Dashboard
- Timetable Screen
- Attendance Report Dialog
- Create Pink Slip Dialog
- AI Agent Sheet

Verify that no `RenderFlex` overflow occurs.

Use appropriate Flutter testing techniques to detect layout exceptions.

---

# 24. TEST LARGE TEXT

Also test accessibility/font scaling.

The UI must remain usable when system text size is increased.

Do not rely on exact text width.

---

# 25. TEST REALISTIC LONG DATA

Use long values during testing.

Examples:

```text
Student:
MUTHU KARTHIGAI SELVAM S

Course:
Artificial Intelligence and Machine Learning Laboratory

Department:
Artificial Intelligence and Data Science

Status:
PENDING APPROVAL

Reason:
Medical emergency and hospital consultation
```

The UI must remain stable.

---

# 26. FINAL VALIDATION

After making changes, run:

```bash
flutter analyze
```

Then:

```bash
flutter test
```

Then:

```bash
flutter test test/responsive_ui_test.dart
```

Then build:

```bash
flutter build apk --debug
```

If possible, test the application on multiple emulator/device resolutions.

---

# 27. FINAL REQUIREMENT

Do not stop after fixing the first overflow.

Perform a complete responsive audit of the entire Flutter application.

Search for all potential layout problems and fix them systematically.

The final application must satisfy:

```text
320×568  → No overflow
360×640  → No overflow
375×667  → No overflow
390×844  → No overflow
412×915  → No overflow
430×932  → No overflow
```

and also remain responsive to intermediate resolutions.

---

# 28. CODE QUALITY

Keep the implementation clean.

Prefer reusable responsive helpers instead of duplicating breakpoint logic throughout the application.

Do not introduce unnecessary dependencies.

Do not rewrite working business logic.

Do not change database functionality.

Do not change authentication.

Do not change the application's existing visual identity.

---

# SUCCESS CRITERIA

The task is complete only when:

- No horizontal overflow exists.
- No vertical overflow exists.
- No `RenderFlex overflowed` errors exist.
- Buttons remain accessible.
- Dialogs fit every supported screen.
- Bottom sheets work with the keyboard.
- Long text is handled safely.
- Statistics adapt to screen width.
- Cards adapt to screen width.
- Headers adapt to screen width.
- Existing colors/design remain unchanged.
- Existing functionality remains unchanged.
- `flutter analyze` passes without newly introduced errors.
- Responsive widget tests pass.

## IMPORTANT

Do not just patch the visible overflow.

**Analyze the entire Flutter project and implement a proper responsive UI architecture so that future dynamic data and different mobile resolutions do not recreate the same problem.**
