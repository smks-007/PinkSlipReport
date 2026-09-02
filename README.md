# 📑 Pink Slip Report

> **Pink Slip Report** is a scalable employee separation management system for securely creating, managing, and generating digital employee exit reports using Flutter, Spring Boot, PostgreSQL, and JWT authentication.

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🌟 Key Features

* **📱 Modern Material 3 UI**: Clean, responsive Flutter mobile and web client with custom vector canvas illustrations.
* **🔐 Complete Authentication Suite**:
  * **Sign In**: Username/password authentication, password visibility toggles, and social login entrypoints (Google & Facebook).
  * **Sign Up**: Account registration with validation and interactive legal agreement terms.
  * **Forgot Password**: One-Time-Password (OTP) recovery workflow and email verification.
* **🛡 Enterprise Security**: JWT-based stateless authentication, BCrypt encryption, and Role-Based Access Control (RBAC).
* **📄 Automated Exit Clearance & Separation**: Digital Pink Slip report generation with departmental clearances (IT, Finance, HR) and verification.

---

## 🏗 Architecture & Modules

```
PinkSlipReport/
├── lib/
│   ├── auth/
│   │   ├── screens/        # Sign In, Sign Up, Forgot Password screens
│   │   ├── theme/          # Centralized AuthTheme tokens (colors, typography, inputs)
│   │   └── widgets/        # Reusable custom UI components (buttons, fields, illustrations)
│   └── main.dart           # App entrypoint and route table
├── test/
│   └── widget_test.dart    # Automated widget integration & validation test suite
├── Implement/              # Design specifications and architecture guidelines
├── UPDATES.md              # Detailed project changelog, commit history, and roadmap
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`>=3.47.0`)
* Dart SDK (`>=3.13.0`)
* Java JDK 17+ (for backend services)
* PostgreSQL 16+ (for separation database)

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

For detailed version history, recent commit logs, and upcoming roadmap items, please refer to [UPDATES.md](file:///c:/Users/Rajavel/.gemini/antigravity/scratch/PinkSlipReport/UPDATES.md).
