# 🚀 Workly: Sync Your Team, Simplify Your Tasks.

<div align="center">

  <img src="https://via.placeholder.com/150/6C63FF/FFFFFF?text=W" alt="Workly Logo" width="120" height="120" style="border-radius: 20px;"/>

  ### The modern workplace task tracker built for speed and simplicity.

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
  [![Language](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

  [Features](#features) • [Installation](#installation) • [Screenshots](#screenshots) • [Architecture](#architecture)

</div>

---

## ⚡ What is Workly?

**Workly** isn't just a todo list. It's a cohesive **team synchronization tool** designed for small groups (4-5 people) to manage on-site tasks effortlessly. 

Built with **Flutter** and **Firebase**, it delivers a premium user experience with:
- **Zero-Friction Onboarding**: Team members join via a simple 6-digit ID. No passwords to forget.
- **Real-Time Synergy**: Updates land efficiently on every device instantly.
- **Visual Context**: tasks aren't just text—they include location tags and images.

---

## ✨ Key Features

### 👑 For Admins (Managers)
- **Secure Dashboard**: Password-protected admin panel.
- **Workplace Generation**: Create a unique workspace in seconds.
- **Rich Task Creation**: Add tasks with **Photos** (Base64/Storage) and **Location Tags**.
- **Progress Tracking**: Instantly see *who* has verified a task as done.
- **Task Editing**: Correct mistakes effortlessly.

### 👥 For Team Members
- **Instant Access**: Join using the **Workplace ID**—no sign-up fatigue.
- **Live Updates**: Watch tasks move from "Pending" to "Completed" in real-time.
- **Focus Mode**: Filter your view to see only what needs attention.
- **One-Tap Completion**: Mark work as done with satisfying micro-interactions.

---

## 🎨 UI/UX Philosophy

We believe B2B apps shouldn't feel boring. Workly features:
- **Glassmorphism**: Subtle transparencies for a modern, airy feel.
- **Motion Design**: Powered by `flutter_animate` for smooth entry and exit transitions.
- **Typography**: Uses **Outfit** (Google Fonts) for clean, legible readability.
- **Color Psychology**: 
  - <span style="color:#6C63FF">█</span> **Indigo**: Trust & Stability (Primary)
  - <span style="color:#00BFA6">█</span> **Teal**: Activity & Success (Secondary)

---

## 🛠️ Architecture

The codebase follows **Clean Architecture** principles to ensure scalability and testability.

```bash
lib/
├── core/                   # 🧱 App-wide constants, theme, and utils
├── features/               # 📦 Feature-first organization
│   ├── auth/               #    - Authentication (Admin/Anonymous)
│   ├── workplace/          #    - Core logic (Create/Join/Manage)
│   ├── tasks/              #    - Task UI components & logic
│   └── dashboard/          #    - Main navigation & state
└── main.dart               # 🚀 Entry point with MultiProvider setup
```

**State Management**: `Provider` (Simple, effective dependency injection).  
**Backend**: `Cloud Firestore` (NoSQL database) + `Firebase Auth`.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Firebase Account](https://firebase.google.com)

### Installation Guide

1. **Clone the Repo**
   ```bash
   git clone https://github.com/adeshpatel700-rgb/Workly.git
   cd Workly
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a project in [Firebase Console](https://console.firebase.google.com).
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`.
   - Enable **Authentication** (Email/Password + Anonymous).
   - Enable **Firestore Database**.
   - *(See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed rules)*

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📸 Screenshots

| Landing Page | Dashboard | Task Details |
|:---:|:---:|:---:|
| <img src="https://via.placeholder.com/250x500?text=Landing" width="200" /> | <img src="https://via.placeholder.com/250x500?text=Dashboard" width="200" /> | <img src="https://via.placeholder.com/250x500?text=Tasks" width="200" /> |

---

<div align="center">

Made with ❤️ by Adesh Patel

</div>
