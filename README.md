# Workly - Workplace Task Tracker

Workly is a modern, production-ready Flutter application designed for small teams to manage and track work assignments effortlessly. Built with a clean architecture, smooth animations, and a delightful UI.

![Workly Banner](https://via.placeholder.com/1200x600.png?text=Workly+App+Preview)

## 🔥 Features

### For Admins
- **Secure Login**: Email and Password authentication.
- **Create Workplace**: Generate a unique Team ID.
- **Task Management**: Post tasks with titles, descriptions, location tags, and optional images.
- **Track Progress**: See real-time updates on who completed tasks.
- **Clean Dashboard**: Manage everything from a central hub.

### For Team Members
- **Easy Join**: No signup needed—just enter your name and the Workplace ID.
- **Real-time Sync**: Tasks update instantly.
- **Filter**: Toggle between All, Pending, and Completed tasks.
- **Mark as Done**: Simple checkbox interaction to complete work.

## 🛠 Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore)
- **Architecture**: Clean Architecture (Feature-based)
- **UI/UX**: Google Fonts (Outfit), Flutter Animate, Glassmorphism touches.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed.
- Firebase Account.

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd workly
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   Follow the instructions in `FIREBASE_SETUP.md` to configure the backend.
   *Crucial: You must run `flutterfire configure` to generate `lib/firebase_options.dart`.*

4. **Run the App**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── core/            # Shared resources (Theme, Colors, Widgets)
├── features/        # Feature-based modules
│   ├── auth/        # Login, Signup, Join Logic
│   ├── dashboard/   # Main Home Screen, Navigation
│   ├── workplace/   # Workplace Management
│   └── tasks/       # Task Display & Creation
└── main.dart        # Entry Point
```

## 🎨 Design System

Workly uses a curated color palette:
- **Primary**: Modern Indigo (`#6C63FF`)
- **Secondary**: Teal Accent (`#00BFA6`)
- **Background**: Soft White (`#F8F9FE`)

## 📱 Screenshots

| Landing | Dashboard | Add Task |
|---------|-----------|----------|
| ...     | ...       | ...      |

---
Built with ❤️ using Flutter.
