# Firebase Configuration Guide for Workly

Workly uses Firebase for Authentication and Cloud Firestore. Follow these steps to set up the backend.

## 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it `workly-app` (or similar).
3. Disable Google Analytics (optional, for simplicity).
4. Create project.

## 2. Enable Authentication
1. Go to **Build > Authentication** in the sidebar.
2. Click **Get Started**.
3. Enable **Email/Password** provider (for Admins).
4. Enable **Anonymous** provider (for Normal Users).
5. Click **Save**.

## 3. Enable Cloud Firestore
1. Go to **Build > Firestore Database**.
2. Click **Create Database**.
3. Choose a location (e.g., `us-central1`).
4. Start in **Test Mode** (or Production Mode).
5. Click **Create**.

### Firestore Security Rules
Go to the **Rules** tab in Firestore and paste the following rules to secure your data while allowing the app to function:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User Profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Workplaces
    match /workplaces/{workplaceId} {
      // Any auth user can read basic workplace info (to join)
      allow read: if request.auth != null;
      // Only admins can create
      allow create: if request.auth != null;
      // Updates (joining) allowed
      allow update: if request.auth != null;
      
      // Tasks Subcollection
      match /tasks/{taskId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null; // Refine this for production to check roles
      }
    }
  }
}
```

## 4. Connect to Flutter App
You have two options:

### Option A: Using FlutterFire CLI (Recommended)
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Log in: `firebase login`
4. Run in your terminal at the project root:
   ```bash
   flutterfire configure
   ```
5. Select your project and platforms (Android/iOS).
6. This will automatically replace `lib/firebase_options.dart` with the correct keys.

### Option B: Manual Setup
If you cannot use the CLI, download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase Console project settings and place them in `android/app/` and `ios/Runner/` respectively. Then manually configure `lib/firebase_options.dart`.

## 5. Storage (Optional)
If you want to use Firebase Storage instead of Base64 strings for images (recommended for production):
1. Enable **Storage** in Firebase Console.
2. Update the app to upload images to Storage and save URLs in Firestore.

Note: The current implementation uses Base64 strings stored in Firestore for valid simplicity on the Free tier.
