# PinkSlipReport — Responsive UI Migration Guide

> **Scope**: Layout only. Zero changes to Supabase, JWT, services, models, or colors.

---

## Step 0 — Add the responsive utility (do this first)

Copy `lib/core/utils/responsive_utils.dart` into your project.

Add the import to any screen you're fixing:
```dart
import 'package:your_app/core/utils/responsive_utils.dart';
```

---

## Step-by-Step Fix Order

### ✅ Fix 1 & 2 — CRASH: Unbounded VerticalDivider (HOD Dashboard)

**File:** `hod_dashboard_screen.dart`

Find any `VerticalDivider(...)` inside a `Row` and replace:

```dart
// ❌ BEFORE — crashes (unbounded height in Row)
VerticalDivider(color: Colors.white30)

// ✅ AFTER — always safe
Container(width: 1, height: 32, color: Colors.white30)
```

---

### ✅ Fix 3 — CRASH: Double keyboard padding (Student Dashboard)

**File:** `student_dashboard_screen.dart`

```dart
// ❌ BEFORE — padding applied twice
showModalBottomSheet(
  context: context,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,  // 1st time
    ),
    child: ...,
  ),
);

// ✅ AFTER — single inset, controlled by the sheet
showModalBottomSheet(
  context: context,
  isScrollControlled: true,   // ← hand inset control to sheet
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(
      bottom: ctx.bottomInset + 16,   // ← only once, inside the sheet
    ),
    child: ...,
  ),
);
```

---

### ✅ Fix 4 — Sign-In Header height

**File:** `sign_in_screen.dart`

```dart
// ❌ BEFORE
SizedBox(height: 290, child: Stack(...))

// ✅ AFTER
SizedBox(
  height: context.clampedHeight(0.33, 190.0, 280.0),
  child: Stack(clipBehavior: Clip.hardEdge, children: [...]),
)
```

---

### ✅ Fix 5 — Sign-In button rigid height

**File:** `sign_in_screen.dart`

```dart
// ❌ BEFORE
SizedBox(height: 52, child: ElevatedButton(...))

// ✅ AFTER
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    minimumSize: const Size(double.infinity, 48),
  ),
  ...
)
```

---

### ✅ Fix 6 — Forgot Password header spacers

**File:** `forgot_password_screen.dart`

```dart
// ❌ BEFORE
Row(children: [
  SizedBox(width: 44),   // rigid spacer
  Text('CREDENTIAL RECOVERY'),
  SizedBox(width: 44),
])

// ✅ AFTER
Row(children: [
  SizedBox(width: 44, child: BackButton()),
  Expanded(child: Column(children: [
    Text('CREDENTIAL RECOVERY', overflow: TextOverflow.ellipsis),
    _FacultyBadge(),         // responsive font size inside
  ])),
  const SizedBox(width: 44),  // mirror spacer
])
```

Badge font size:
```dart
// ❌ BEFORE
fontSize: 11

// ✅ AFTER
fontSize: context.responsiveFontSize(compact: 9.5, normal: 11.0)
```

---

### ✅ Fix 7 — Security Verification PIN pad clipping

**File:** `security_verification_screen.dart`

```dart
// ❌ BEFORE
body: Column(children: [...])

// ✅ AFTER
body: SafeArea(
  child: SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: availableHeight),
      child: IntrinsicHeight(child: Column(children: [...])),
    ),
  ),
)
```

PIN pad spacing:
```dart
// ❌ BEFORE: fixed spacing: 12

// ✅ AFTER
spacing: context.isCompact ? 8.0 : 12.0
```

---

### ✅ Fix 8 — HOD Dashboard 4-stat banner (adaptive layout)

**File:** `hod_dashboard_screen.dart`

```dart
// ❌ BEFORE
GridView.count(crossAxisCount: 4, children: [...])  // height bloat + crash

// ✅ AFTER
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth < 360) {
    return Column(children: [
      Row(children: [Expanded(child: stat0), divider, Expanded(child: stat1)]),
      SizedBox(height: 12),
      Row(children: [Expanded(child: stat2), divider, Expanded(child: stat3)]),
    ]);
  }
  return Row(children: [
    Expanded(child: stat0), divider,
    Expanded(child: stat1), divider,
    Expanded(child: stat2), divider,
    Expanded(child: stat3),
  ]);
})
```

---

### ✅ Fix 9 — HOD segmented nav tab text clipping

**File:** `hod_dashboard_screen.dart`

```dart
// ❌ BEFORE
Text(label)

// ✅ AFTER
Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1))

// Padding:
// ❌ BEFORE: padding: EdgeInsets.symmetric(horizontal: 10)
// ✅ AFTER:  padding: EdgeInsets.symmetric(horizontal: context.tabHorizontalPadding)
```

---

### ✅ Fix 10 — Pink slip approval card action buttons

**File:** `hod_dashboard_screen.dart` and `advisor_dashboard_screen.dart`

```dart
// ❌ BEFORE
Row(children: [TextButton('View'), Spacer(), OutlinedButton('Reject'), ElevatedButton('Approve')])

// ✅ AFTER
Wrap(
  alignment: WrapAlignment.spaceBetween,
  spacing: 8,
  runSpacing: 8,
  children: [viewButton, Row(children: [rejectButton, approveButton])],
)
```

---

### ✅ Fix 11 — Pink slip card header badges

```dart
// ❌ BEFORE
Row(children: [Chip('ON-DUTY OD PASS'), Chip(status), Spacer(), Text(date)])

// ✅ AFTER
Wrap(spacing: 6, runSpacing: 4, children: [badge1, badge2, dateText])
```

---

### ✅ Fix 12 — Advisor AppBar title at 1.5× text scale

**File:** `advisor_dashboard_screen.dart`

```dart
// ❌ BEFORE — in AppBar title:
Column(children: [Text(portalName), Text(subtitle)])

// ✅ AFTER
Expanded(child: Column(children: [
  Text(portalName, overflow: TextOverflow.ellipsis, maxLines: 1),
  Text(subtitle,   overflow: TextOverflow.ellipsis, maxLines: 1),
]))
```

---

### ✅ Fix 13 — Timetable period card badge overflow

**File:** `timetable_screen.dart`

```dart
// ❌ BEFORE
Text(entry.subjectShort)

// ✅ AFTER
Flexible(child: Text(entry.subjectShort, maxLines: 1, overflow: TextOverflow.ellipsis))
```

---

### ✅ Fix 14 — Dialog vertical clipping on 568 px devices

**Files:** All dialog files

```dart
// ❌ BEFORE
Dialog(child: ...)

// ✅ AFTER
Dialog(
  constraints: context.dialogConstraints(maxWidth: 580),   // 88% height, 95% width
  child: SingleChildScrollView(child: ...),
)
```

---

### ✅ Fix 15 — AI Agent sheet header overflow

**File:** `role_ai_agent_sheet.dart`, `jarvis_fab.dart`

```dart
// ❌ BEFORE
Column(children: [Text(title), Text(badge)])

// ✅ AFTER
Flexible(child: Column(children: [
  Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
  Text(badge, overflow: TextOverflow.ellipsis, maxLines: 1),
]))
```

---

## Running the Test Suite

```powershell
# New responsive tests only
flutter test test/responsive_ui_test.dart

# Full regression
flutter test

# Static analysis — target: 0 errors, 0 warnings
flutter analyze
```

### Replacing placeholders in the test file

In `test/responsive_ui_test.dart`, find the `_screens` map and replace each
`_PlaceholderScreen(name: '...')` with the real import:

```dart
// ❌ Placeholder
'SignInScreen': (_) => const _PlaceholderScreen(name: 'SignIn'),

// ✅ Real widget
'SignInScreen': (_) => const SignInScreen(),
```

---

## Priority Order (if you want to ship incrementally)

| Priority | Fix | Risk |
|---|---|---|
| 🔴 P0 | Bounded divider (crash) | Zero — one widget swap |
| 🔴 P0 | isScrollControlled on bottom sheet | Zero — one flag change |
| 🟠 P1 | clampedHeight on sign-in header | Low — layout only |
| 🟠 P1 | Flexible on all tab labels | Low — wrapping only |
| 🟠 P1 | Wrap on all action button rows | Low — layout only |
| 🟡 P2 | dialogConstraints on all dialogs | Low — sizing only |
| 🟡 P2 | SafeArea + scroll on PIN screen | Low — wrapper only |
| 🟢 P3 | responsive_utils.dart | None — new file |
| 🟢 P3 | responsive_ui_test.dart | None — test only |
