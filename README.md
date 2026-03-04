# Together

A social mobile application that helps people find companions to join activities together — from food, exercise, travel, to concerts.

---

## Overview

Together solves the problem of wanting to do activities but having no one to go with. Users can create or join activity posts, see who is hosting, how many spots are left, and join with one tap. Hosts get notified when someone joins their activity.

---

## Features

- **Authentication** — Email/password registration and login via Firebase Auth
- **Create Activity** — Post an activity with title, description, category, date, time, location, image, and max participants
- **Browse & Filter** — View all activities filtered by category (Food, Exercise, Travel, Concert)
- **Join / Leave** — One-tap join with participant limit enforcement
- **Activity Detail** — Full detail view with participant avatars, host info, and activity image
- **Comments** — Real-time chat/comment section on each activity, available only to joined participants and the host
- **Notifications** — Host receives a notification when someone joins their activity
- **Profile Page** — View joined and created activities, edit display name, change profile photo
- **Delete Activity** — Hosts can delete their own activities including all associated comments

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| Backend | Firebase |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Hosting | Firebase Hosting |
| Language | Dart |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, auth state routing
├── firebase_options.dart      # Firebase configuration
├── login_page.dart            # Login screen
├── register_page.dart         # Registration screen
├── home_page.dart             # Activity feed with category filter
├── create_activity_page.dart  # Create new activity form
├── activity_detail_page.dart  # Activity detail, join/leave, comments
├── profile_page.dart          # User profile, stats, activity history
└── notification_page.dart     # Notification center
```

---

## Firestore Data Structure

```
users/{uid}
  - displayName, email, phone, gender, dob, photoUrl, createdAt

activities/{activityId}
  - title, description, date, time, location, category
  - maxParticipants, participants[], imageUrl
  - hostId, hostName, hostEmail, createdAt

  comments/{commentId}
    - userId, userName, photoUrl, message, createdAt

notifications/{notificationId}
  - toUserId, fromUserId, fromUserName
  - activityId, activityTitle, message, isRead, createdAt
```

---

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase CLI
- A Firebase project with Auth, Firestore, and Storage enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/VachiraLX/Together.git
cd Together/together

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run

# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /activities/{activityId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null &&
                    request.auth.uid == resource.data.hostId;

      match /comments/{commentId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow delete: if request.auth != null &&
                      request.auth.uid == resource.data.userId;
      }
    }

    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    match /notifications/{id} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Developer

| Field | Info |
|-------|------|
| Name | Vachira Loyweaha |
| Student ID | 6731503117 |
| Course | 1305216 Mobile Application Development |
