# SEAfety Travel

A Flutter-based travel planning and safety information application designed to help tourists explore destinations, access travel packages, and stay informed about safety conditions.

The application provides separate interfaces for **Tourists, Travel Agencies, and Tourism Officers**, allowing each user type to access features relevant to their role.

## Features

### Tourist
- Explore tourist destinations and view destination information.
- Browse available travel packages.
- Manage planned trips and travel details.
- Communicate with travel agencies.
- View safety alerts and relevant travel information.

### Travel Agency
- Create, edit, publish, and manage travel packages.
- View available destinations.
- Manage customer bookings.
- Respond to customer enquiries.
- Communicate with customers through in-app messaging.
- Update enquiry statuses and schedule follow-up reminders.

### Tourism Officer
- Manage destination information.
- Publish and manage safety alerts.
- View safety-related information and map interfaces.
- Access emergency resource information.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application development |
| Dart | Application programming language |
| Firebase Authentication | User registration and authentication |
| Cloud Firestore | Cloud database and application data storage |
| Cloudinary | Travel package image uploads |
| Git & GitHub | Source code management and collaboration |

## Application Structure

The source code is organised into separate modules to keep the application manageable and easier to maintain.

```text
lib/
├── agency/
│   ├── screens/
│   └── services/
├── officer/
│   ├── screens/
│   └── services/
├── tourist/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── shared/
│   ├── auth/
│   ├── models/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── cloudinary_service.dart
├── firebase_options.dart
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- A Firebase project
- A Cloudinary account

### Installation

1. Clone this repository:

```bash
git clone https://github.com/keraitaha/SEAFety-Travel
```

2. Navigate to the project directory:

```bash
cd YOUR-REPOSITORY
```

3. Install the required dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your Flutter application using the FlutterFire CLI and your own Firebase project.

5. Configure Cloudinary with your own cloud name and unsigned upload preset.

6. Add your Google Maps API key (used by the Tourism Officer safety map).
   The key is not committed to this repository.

   - Android: copy `android/secrets.properties.example` to
     `android/secrets.properties` and set your key:

     ```properties
     MAPS_API_KEY=your_google_maps_api_key
     ```

   - Web (only if running on web): open `web/index.html` and replace
     `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key. Do not commit a real key.

   Without a key, the app still builds and runs; only the safety map appears
   blank.

7. Run the application:

```bash
flutter run
```

## Notes

- Firebase and Cloudinary configurations must be set up before running the application.
- Firestore security rules should be configured to protect user data and restrict access according to user roles.
- This project was developed as part of a group academic assignment.

## Project Purpose

SEAfety Travel aims to bring travel planning and safety information together in one application, making it easier for tourists to explore destinations while allowing travel agencies and tourism officers to manage their respective services.