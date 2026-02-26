# CBT Mobile App

Mobile application for students to take Computer-Based Tests (CBT), built with Flutter. Students can take exams, view results, and manage their profile.

## Features

### Exam Taking
- **Exam List** — View assigned exams (SCHEDULED, ONGOING)
- **Start Exam** — Start exam session, receive question list from server
- **Auto-Save** — Answers automatically saved to server on selection
- **Question Types** — Single Choice, Multiple Choice, Essay
- **Countdown Timer** — Timer based on global `end_date` deadline
- **Auto-Finish** — Exam auto-finishes when timer expires (client-side + server-side backup)
- **Question Picker** — Navigate between questions, see answered/unanswered status
- **Unanswered Warning** — Warning when finishing with unanswered questions
- **Beautified Dialogs** — Consistent dialog design system with gradient icons, rounded corners, and shadow effects across all exam-related dialogs

### Anti-Cheat System
- **Background Detection** — If app is backgrounded for >10 seconds → auto-block
- **Inactive State Detection** — Detects `AppLifecycleState.inactive` with 300ms debounce to prevent false positives from system overlays
- **Blocked Page** — Dedicated page shown when student is blocked
- **Unlock Code** — Requires unlock code from exam supervisor (generated via admin dashboard)

### History & Results
- **History Tab** — List of completed exams with scores
- **Result Detail** — Final score, submission date

### Profile
- **View Profile** — Name, classroom, grade level, major
- **Edit Profile** — Update name and profile photo
- **Logout** — Clear session and return to login

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter (Dart SDK ^3.9.2) |
| HTTP Client | http ^1.6.0 |
| Local Storage | shared_preferences ^2.5.4 |
| Date Formatting | intl ^0.20.2 |
| Image Picker | image_picker ^1.2.1 |

## Setup

### Prerequisites

- Flutter SDK 3.9+
- Android Studio or VS Code with Flutter extension
- Android Emulator or physical device
- CBT Backend API running at `http://localhost:3000`

### Installation

```bash
cd cbt_app
flutter pub get
```

### API URL Configuration

Edit `lib/utils/url.dart`:

```dart
class Url {
  static const bool useEmulator = true;           // true for emulator, false for device
  static const String _localIP = "192.168.x.x";  // Your computer's IP
  static const String _port = "3000";
  static const String _emuHost = "10.0.2.2";     // Android emulator → host

  static String get baseUrl {
    final host = useEmulator ? _emuHost : _localIP;
    return "http://$host:$_port/api";
  }
}
```

- **Android Emulator**: Set `useEmulator = true` (uses `10.0.2.2` which maps to host machine)
- **Physical Device**: Set `useEmulator = false`, replace `_localIP` with your computer's local IP

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Build APK
flutter build apk
```

## Coding Standards

### Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Dart File | snake_case | `quiz_page.dart`, `exam_controller.dart` |
| Class | PascalCase | `ExamController`, `QuizPage` |
| Function/Method | camelCase | `startExam()`, `submitAnswer()` |
| Variable | camelCase | `examList`, `isLoading` |
| Constant | camelCase or UPPER_SNAKE | `baseUrl`, `_port` |
| Widget | PascalCase | `ExamCard`, `QuestionPicker` |
| Model Field | camelCase (Dart) | `endDate`, `durationMinutes` |
| JSON Key | snake_case (API) | `end_date`, `duration_minutes` |

### Code Style

- **Architecture** — MVC pattern: Models, Views, Controllers, Services
- **Models** — Data classes with `fromJson()` factory constructors for API response parsing
- **Controllers** — Business logic, state management, API call orchestration
- **Services** — HTTP calls to backend API endpoints
- **Views** — UI widgets (StatefulWidget for interactive pages)
- **Widgets** — Reusable UI components (cards, dialogs, headers)
- **State Management** — `setState()` within StatefulWidget (no external state management library)
- **Navigation** — `Navigator.push()` / `Navigator.pushReplacement()`
- **Error Handling** — Try/catch around API calls, `ScaffoldMessenger` for user-facing errors
- **Session** — JWT token stored via `SharedPreferences`, managed by `SessionManager`

### Project Structure

```
lib/
├── main.dart                     # Entry point + BottomNavigationBar
├── controllers/
│   ├── auth_controller.dart      # Login/logout logic
│   ├── exam_controller.dart      # Exam operations (start, submit, finish)
│   ├── home_controller.dart      # Home page logic
│   └── profile_controller.dart   # Profile operations
├── models/
│   ├── user_model.dart           # User model from API
│   ├── exam_model.dart           # Exam model (questions, timer, etc.)
│   ├── exam_response_model.dart  # Response: GET /students/exams
│   ├── exam_result_response_model.dart  # Response: GET /exam-results/my-results
│   ├── start_exam_response_model.dart   # Response: POST /students/exams/start
│   └── quiz_model.dart           # Per-question model (answer, status)
├── services/
│   ├── login_service.dart        # API: POST /auth/login
│   ├── exam_service.dart         # API: students/exams/*, exam-results/*
│   └── profile_service.dart      # API: GET /auth/me, PATCH /auth/profile
├── utils/
│   ├── url.dart                  # API base URL configuration
│   ├── session_manager.dart      # Token + profile image storage
│   └── helpers.dart              # Date formatter, exam type helper
├── views/
│   ├── login_page.dart           # Login page
│   ├── home_page.dart            # Tab 1: exam list
│   ├── history_page.dart         # Tab 2: exam history + scores
│   ├── profile_page.dart         # Tab 3: profile + logout
│   ├── quiz_page.dart            # Exam taking page (timer, questions, navigation)
│   ├── quiz_essay_page.dart      # Essay question widget
│   ├── quiz_multiple_choice_page.dart  # MC question widget
│   ├── quiz_picker.dart          # Question navigation grid
│   ├── quiz_blocked_page.dart    # Blocked student page
│   └── quiz_end_page.dart        # Post-exam page
├── widgets/
│   ├── exam_card.dart            # Exam card on home
│   ├── exam_list_section.dart    # Exam list section
│   ├── history_card.dart         # History card
│   ├── home_header.dart          # Home page header
│   ├── navbar.dart               # Bottom navigation bar
│   ├── picker_item.dart          # Question picker item
│   ├── start_dialog.dart         # Start exam confirmation
│   ├── finish_quiz_dialog.dart   # Finish exam confirmation
│   ├── end_quiz_dialog.dart      # Exit exam dialog
│   ├── unanswered_warning_dialog.dart       # Unanswered warning (exit)
│   ├── unanswered_finish_warning_dialog.dart # Unanswered warning (finish)
│   ├── loading_state.dart        # Loading widget
│   ├── error_state.dart          # Error widget
│   └── dialogs/
│       ├── loading_dialog.dart           # Reusable utility dialogs (loading, error, success, confirm)
│       ├── exit_all_answered_dialog.dart # Exit quiz dialog when all questions answered
│       ├── logout_dialog.dart            # Logout confirmation dialog
│       └── change_password_dialog.dart   # Change password form dialog
└── style/
    └── style.dart                # App colors and theme
```

## Exam Taking Flow

```
Login → Home (exam list) → Select exam → Start Dialog
  → Quiz Page (timer + questions)
    → Answer question (auto-save to server)
    → Navigate: Next / Previous / Picker
    → Finish → Confirmation → Submit to server
      → Return to Home
```

## Global Deadline Timer

The countdown timer uses the **global `end_date`** from the exam. All students share the same deadline regardless of when they personally started the exam.

```dart
// In quiz_page.dart _initializeTimer()
final DateTime? endTime = widget.exam.endDate;
```

The `duration_minutes` field is only used for informational display (e.g., "Duration: 90 minutes"). It does **not** affect the timer calculation.

When the timer reaches zero:
1. **Client-side**: Flutter auto-calls `POST /students/exams/finish`
2. **Server-side**: Backend scheduler checks every 60 seconds and auto-finishes any sessions past `end_date`

This dual approach ensures exams are always finalized even if the app crashes or loses connection.

## Anti-Cheat System

The app monitors `AppLifecycleState` changes:

1. When app goes to background → records timestamp
2. When app receives `inactive` state → starts 300ms debounce timer (prevents false triggers from system dialogs)
3. When app returns to foreground → checks elapsed time
4. If elapsed > 10 seconds:
   - Navigates to `QuizBlockedPage`
   - Blocked state saved to `SharedPreferences` (persists across app restart)
4. Admin generates an unlock code via the dashboard
5. Student enters unlock code to resume the exam

## API Endpoints Used

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | Student login |
| `/api/auth/me` | GET | Get profile |
| `/api/auth/profile` | PATCH | Update profile (name, photo) |
| `/api/students/exams` | GET | List student's assigned exams |
| `/api/students/exams/start` | POST | Start exam session |
| `/api/students/exams/answer` | POST | Submit answer per question |
| `/api/students/exams/finish` | POST | Finish exam |
| `/api/exam-results/my-results` | GET | Exam result history |

## License

MIT
