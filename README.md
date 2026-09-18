# 📑 SMART PRO — Pink Slip & Attendance Management System

> **Pink Slip Report (SMART PRO)** is a real-time academic attendance ledger, 2-tier On-Duty (OD) / Leave approval pipeline, and digital Pink Slip clearance platform built for the **Department of Artificial Intelligence & Data Science (AI & DS)** at **V.S.B. Engineering College, Karur**.

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🌟 Key Features

* **📱 Modern Material 3 Dashboards**: Tailored role-based portals for **Students**, **Class Advisors**, and the **Head of Department (HOD)**.
* **🔐 Supabase Cloud Authentication & RBAC**:
  * Strict database-driven role verification (`HOD`, `ADVISOR`, `STUDENT`) via `public.users` and authenticated JWT tokens.
  * Inactivity timeout protection, brute-force lockout safeguards, and password recovery workflows.
* **📅 1-Month Day-Wise Attendance Ledger**:
  * 30+ working day calendar horizon for all 622 AIDS students across 10 sections (`II-AIDS-A..D`, `III-AIDS-A..D`, `IV-AIDS-A..B`).
  * Instant 1-click batch presence/absent/OD toggling with immutable prior approval locking (*"If updated, don't overwrite"*).
* **📑 2-Tier Leave & On-Duty Approval Workflow**:
  * **Student**: Apply for Leaves/ODs with letter upload and digital reason submission.
  * **Class Advisor**: Review, endorse, and forward to HOD or reject with remarks.
  * **HOD**: Final executive approval/rejection with automated attendance ledger pre-locking.
* **📊 Visual Intelligence & Analytics**:
  * Section-wise attendance benchmarking against Anna University's 75% statutory threshold.
  * Period-by-period attrition heatmaps and 30-day attendance trend curves.
* **🤖 Jarvis AI Copilot**:
  * Natural language query interface for student profiles, attendance analytics, detention forecasting, and automated bilingual (Tamil/English) alert drafting.

---

## 🏗 Architecture & Modules

```
PinkSlipReport/
├── lib/
│   ├── auth/               # Authentication screens, theme tokens & custom widgets
│   ├── chatbot/            # Jarvis AI Copilot dialogs and telemetry widgets
│   ├── core/
│   │   ├── constants/      # App styles, color tokens & Supabase configurations
│   │   ├── data/           # Official student directory datasets (622 students)
│   │   ├── models/         # Domain models (User, Student, Attendance, Leave, Notice)
│   │   ├── services/       # Supabase, Auth, Data, AI Agent, and Gemini services
│   │   └── widgets/        # Reusable shared UI widgets & dialogs
│   ├── dashboard/
│   │   ├── advisor/        # Class Advisor dashboard & day-wise attendance ledger
│   │   ├── hod/            # HOD department overview, approval inbox & analytics
│   │   ├── student/        # Student dashboard, leave submissions & slip viewer
│   │   ├── timetable/      # Section timetables & schedule manager
│   │   └── shared/         # Shared reporting, promotion & slip viewer dialogs
│   └── main.dart           # App entrypoint, theme setup & route guards
├── supabase/
│   └── migrations/         # PostgreSQL schema migrations, RLS policies & triggers
├── test/                   # Automated widget & unit test suites
├── UPDATES.md              # Detailed changelog, version history & roadmap
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`>=3.47.0`)
* Dart SDK (`>=3.13.0`)
* Supabase project instance (URL and Anon Key configured via environment variables or `supabase_config.dart`)

### Installation & Run

1. **Clone or navigate to the repository**:
   ```bash
   git clone https://github.com/smks-007/PinkSlipReport.git
   cd PinkSlipReport
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

4. **Execute automated tests**:
   ```bash
   flutter test
   ```

---

## 📖 Changelog & Updates

For detailed version history and changelog, please refer to [UPDATES.md](file:///d:/Dept/PinkSlipReport-main/UPDATES.md).
