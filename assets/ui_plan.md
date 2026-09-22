You are a Flutter UI specialist. Refactor the PinkSlipReport Flutter application 
to fix all responsiveness and overflow issues across all screens. Follow these 
strict constraints:

## NON-REGRESSION RULES (DO NOT TOUCH)
- Zero changes to: Supabase auth, database queries, JWT handling, models, or 
  any service class (AuthService, MockDataService, AiAgentService, GeminiService).
- Preserve all brand colors, gradients, typography, iconography, and logos exactly.
- Only modify layout constraints, flex wrappers, scroll containers, and sizing.

---

## STEP 1 — Create Responsive Utility (Do this first)

Create file: lib/core/utils/responsive_utils.dart

```dart
import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isUltraCompact => screenWidth < 340;
  bool get isCompact => screenWidth < 360;
  bool get isMedium => screenWidth < 400;

  double get responsiveHorizontalPadding =>
      isCompact ? 12.0 : isMedium ? 16.0 : 20.0;

  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  double clampedHeight(double fraction, double min, double max) =>
      (screenHeight * fraction).clamp(min, max);

  BoxConstraints get dialogConstraints => BoxConstraints(
        maxHeight: screenHeight * 0.88,
        maxWidth: screenWidth * 0.95,
      );
}
```

---

## STEP 2 — Fix Authentication Screens

### sign_in_screen.dart
- Replace `height: 290` on `_buildSkyCloudHeader` with:
  `height: context.clampedHeight(0.33, 190.0, 280.0)`
- Position decorative cloud widgets using proportional offsets 
  (multiply fixed offsets by `context.screenWidth / 390`).
- Change every Sign In / Submit button from:
  `height: 52` → `constraints: BoxConstraints(minHeight: 48)` 
  with `paddingVertical: 14`.
- Wrap connection badge text and security footer text in 
  `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`.

### forgot_password_screen.dart
- In `_buildHeader`, replace rigid `SizedBox(width: 44)` spacers 
  with `Expanded`/`Flexible` centered branding column.
- Make `'FACULTY CREDENTIAL RECOVERY'` badge font size responsive:
  `fontSize: context.isCompact ? 9.0 : 11.0`
- Wrap badge text in `Flexible` with `TextOverflow.ellipsis`.

### security_verification_screen.dart
- Wrap entire screen body in:
  `SingleChildScrollView(physics: BouncingScrollPhysics())`
- Wrap in `SafeArea`.
- Reduce keypad button vertical spacing when `context.isCompact`:
  `spacing: context.isCompact ? 8.0 : 12.0`

---

## STEP 3 — Fix HOD Dashboard (hod_dashboard_screen.dart)

### Executive Summary Banner (4 stats)
Replace the flat `Row` with a `LayoutBuilder`:
```dart
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth < 360) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [/* Total Enrolled, Present Today, Absentees, Pending Slips */],
    );
  }
  return Row(
    children: [
      Expanded(child: /* stat 1 */),
      VerticalDivider(),
      Expanded(child: /* stat 2 */),
      VerticalDivider(),
      Expanded(child: /* stat 3 */),
      VerticalDivider(),
      Expanded(child: /* stat 4 */),
    ],
  );
})
```

### Segmented Navigation Bar (4 tabs)
- Wrap each tab label `Text` in 
  `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`.
- Reduce icon+label padding when compact:
  `padding: EdgeInsets.symmetric(horizontal: context.isCompact ? 6 : 12)`

### Pink Slip Approval Card — Action Buttons
Replace the `Row` + `Spacer()` button row with:
```dart
Wrap(
  alignment: WrapAlignment.end,
  spacing: 8,
  runSpacing: 8,
  children: [
    // View Voucher button
    // Reject button  
    // Sign & Approve button
  ],
)
```

### Header Badges Row
Replace linear `Row` with:
```dart
Wrap(
  spacing: 6,
  runSpacing: 4,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [/* ON-DUTY badge, status chip, date */],
)
```

---

## STEP 4 — Fix Class Advisor Dashboard (advisor_dashboard_screen.dart)

### App Bar Title
Wrap the title `Column` inside `_buildAppBar` in `Expanded`:
```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('SMART PRO', overflow: TextOverflow.ellipsis),
      Text('Dept of AI & DS • Class Advisor Portal', 
           overflow: TextOverflow.ellipsis),
    ],
  ),
)
```

### _PinkSlipTile — Bottom Action Buttons
Convert the bottom `Row` to:
```dart
Wrap(
  alignment: WrapAlignment.end,
  spacing: 8,
  runSpacing: 8,
  children: [
    // View Voucher
    // Reject
    // Endorse & Forward
  ],
)
```

### Stats Overview Cards
Wrap each stat card in `Expanded` inside its parent `Row`.
Add `overflow: TextOverflow.ellipsis` and `maxLines: 1` to all label texts.

---

## STEP 5 — Fix Student Dashboard (student_dashboard_screen.dart)

### Profile Header Stat Row
Wrap each metric column in `Expanded`:
```dart
Row(
  children: [
    Expanded(child: /* Class Strength metric */),
    Expanded(child: /* Present Today metric */),
    Expanded(child: /* Absentees metric */),
  ],
)
```

### _SubmitLeaveModal — Keyboard Safety
Change the bottom sheet call to:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // ADD THIS
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: ctx.bottomInset), // ADD THIS
    child: _SubmitLeaveModal(),
  ),
);
```

---

## STEP 6 — Fix Timetable Screen (timetable_screen.dart)

### Section Header Card
Wrap room + section info in `Expanded`:
```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(room, overflow: TextOverflow.ellipsis),
      Text(section, overflow: TextOverflow.ellipsis),
    ],
  ),
)
```

### Period Item — Subject Title vs Badge
```dart
Row(
  children: [
    Flexible(
      child: Text(
        entry.subjectShort,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    SizedBox(width: 6),
    // LAB / THEORY badge (fixed width, no Flexible)
  ],
)
```

---

## STEP 7 — Fix Shared Dialogs

### attendance_report_viewer_dialog.dart — 4-Column Metric Banner
```dart
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth < 400) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [/* Attendance, Present, Absent Today, On-Duty */],
    );
  }
  return Row(
    children: [
      Expanded(child: /* metric 1 */),
      Expanded(child: /* metric 2 */),
      Expanded(child: /* metric 3 */),
      Expanded(child: /* metric 4 */),
    ],
  );
})
```

### create_pink_slip_dialog.dart
Replace fixed `maxHeight: 780` with:
```dart
constraints: BoxConstraints(
  maxHeight: MediaQuery.sizeOf(context).height * 0.88,
),
```

### jarvis_fab.dart & role_ai_agent_sheet.dart
Wrap all sheet header title and badge texts in:
```dart
Flexible(child: Text(..., overflow: TextOverflow.ellipsis, maxLines: 1))
```

---

## STEP 8 — Create Responsive Test Suite

Create file: test/responsive_ui_test.dart

Test every primary screen and dialog across these 4 sizes:
- 320 × 568 (ultra-compact)
- 360 × 640 (standard compact Android)
- 390 × 844 (standard iPhone)
- 430 × 932 (large modern phone)

For each screen × size combination:
1. Pump the widget with `tester.binding.setSurfaceSize(size)`.
2. Assert `tester.takeException() == null` (zero RenderFlex overflows).
3. Repeat with `tester.platformDispatcher.textScaleFactorTestValue = 1.5`.

---

## VERIFICATION

After all changes run:
```bash
flutter analyze          # must return 0 warnings
flutter test             # all 38 existing tests must pass
flutter test test/responsive_ui_test.dart  # all new responsive tests must pass
```

Do NOT modify any business logic, service, model, or authentication file.
Only layout files are in scope.