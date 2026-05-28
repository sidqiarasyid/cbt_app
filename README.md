# CBT Mobile App

Native mobile application for students to take Computer-Based Tests (CBT). Students can view assigned exams, take exams with auto-save, view results, and manage profiles.

**Built with:** Flutter 3.9+ | Dart SDK 3.9.2+ | HTTP client | SharedPreferences

---

## Features

### Exam Taking
- **Exam List** — View all assigned exams with status (SCHEDULED, ONGOING)
- **Start Exam** — Begin exam session, receive question list from server
- **Auto-Save Answers** — Submit answers to server automatically on selection (no manual submit)
- **Question Types** — Single Choice, Multiple Choice, Essay text response
- **Countdown Timer** — Real-time timer based on global `end_date` deadline
- **Question Navigation** — View all questions at once, jump to any question
- **Progress Tracking** — Visual indicator of answered/unanswered questions
- **Beautified Dialogs** — Gradient icons, rounded corners, shadow effects on all exam dialogs
- **Auto-Finish** — Exam auto-finishes when timer expires (client-side + server-side backup)
- **Unanswered Warning** — Alert dialog before finishing with unanswered questions

### Anti-Cheat System
- **Background Detection** — App running time tracked; block if backgrounded >10 seconds
- **Inactive State Detection** — Detects system overlay (AppLifecycleState.inactive) with 300ms debounce
- **Blocked Page** — Dedicated UI shown when student is blocked from exam
- **Unlock Code** — Requires unlock code from exam supervisor (generated via admin dashboard)
- **Persistent State** — Block status persists in local storage (SharedPreferences)

### History & Results
- **History Tab** — List of completed exams with final scores
- **Result Detail** — Final score, submission timestamp, question breakdown
- **Download Results** — Export results (optional feature)

### Profile Management
- **View Profile** — Display name, classroom, grade level, major, profile photo
- **Edit Profile** — Update name and upload new profile photo
- **Account Settings** — Change password, manage notifications
- **Session Logout** — Clear JWT token and return to login screen

### Authentication
- **Login Screen** — Username and password authentication via backend
- **Session Management** — JWT token stored in secure local storage
- **Auto-Login** — Resume session if token still valid
- **Logout** — Clear session and return to login

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | 3.9+ |
| Language | Dart | 3.9.2+ |
| HTTP Client | http | 1.6.0+ |
| Local Storage | shared_preferences | 2.5.4+ |
| Secure Storage | flutter_secure_storage | 9.2.4+ |
| State Management | provider (`ChangeNotifier`) | 6.1.2+ |
| Testing | flutter_test + mocktail | 1.0.4+ |

---

## Prerequisites

- **Flutter SDK** v3.9.0 or higher
- **Dart SDK** v3.9.2 or higher (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extension
- **Android Emulator** or **Physical Android Device**
- **CBT Backend API** running at `http://localhost:3000` (or configured server)

**Verify installation:**
```bash
flutter --version
dart --version
flutter doctor
```

---

## Installation & Setup

### 1. Clone Repository

```bash
cd cbt_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API URL

The backend base URL is read from a compile-time `--dart-define` flag (`API_BASE_URL`). The default value lives in [`lib/config/env.dart`](lib/config/env.dart) and is used when no flag is passed.

**Android Emulator (local dev):**
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```
`10.0.2.2` is the emulator gateway that maps to the host machine's `localhost`. Backend must be running on `localhost:3000`.

**Physical Device on same WiFi:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api
```
Replace `192.168.x.x` with your computer's IPv4 (`ipconfig`). Device and computer must be on the same network.

**APK distributed over the internet (e.g. via ngrok / Firebase App Distribution):**
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<your-domain>/api
```

### 4. Set Up Android Emulator (Optional)

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch emulator-name

# Verify connection
flutter devices
```

---

## Running the Application

### Debug Mode (Development)

```bash
flutter run
```

- Hot reload enabled (press `r` to reload, `R` to restart)
- Debug console output visible
- Performance profiling available

### Release Mode

```bash
flutter run --release
```

- Optimized performance
- No debug output
- For user testing

### Build APK (Android Package)

```bash
# Debug APK
flutter build apk

# Release APK (optimized)
flutter build apk --release
```

APK file: `build/app/outputs/flutter-apk/app-release.apk`

---

## Useful Commands

```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Update dependencies to latest
flutter run                  # Debug mode on connected device/emulator
flutter run --release        # Release mode
flutter build apk            # Build release APK
flutter analyze              # Static analysis (lint + type)
flutter test                 # Run unit tests under test/
dart fix --apply             # Auto-apply lint fixes
flutter clean                # Clean build artifacts
flutter doctor               # Check environment setup
flutter devices              # List connected devices
flutter logs                 # View app logs in terminal
```

Pass the backend URL via `--dart-define=API_BASE_URL=...` on any `flutter run` / `flutter build` command.

---

## Project Structure

```
cbt_app/
├── pubspec.yaml                     # Dependencies and project metadata
├── analysis_options.yaml            # Dart linter config
├── devtools_options.yaml
├── README.md                        # This file
│
├── lib/
│   ├── main.dart                    # App entry point
│   │
│   ├── controllers/                 # State + business logic
│   │   ├── auth_controller.dart
│   │   ├── exam_controller.dart
│   │   ├── student_controller.dart
│   │   └── ...
│   │
│   ├── services/                    # HTTP API calls to backend
│   │   ├── auth_service.dart        # Login, logout, profile
│   │   ├── exam_service.dart        # Get exams, submit answers
│   │   └── ...
│   │
│   ├── models/                      # Data classes (fromJson factory constructors)
│   │   ├── user.dart
│   │   ├── exam.dart
│   │   ├── question.dart
│   │   ├── answer.dart
│   │   └── ...
│   │
│   ├── views/                       # StatefulWidget pages/screens
│   │   ├── login_page.dart
│   │   ├── exam_list_page.dart
│   │   ├── quiz_page.dart
│   │   ├── result_page.dart
│   │   ├── profile_page.dart
│   │   └── ...
│   │
│   ├── widgets/                     # Reusable UI components
│   │   ├── custom_button.dart
│   │   ├── custom_dialog.dart
│   │   ├── question_card.dart
│   │   ├── timer_widget.dart
│   │   └── ...
│   │
│   ├── utils/
│   │   ├── url.dart                 # API URL configuration (local IP setup)
│   │   ├── session_manager.dart     # JWT token storage via SharedPreferences
│   │   ├── constants.dart           # App constants, colors, strings
│   │   └── ...
│   │
│   └── providers/ (optional)        # State management (if using Provider/Riverpod)
│
├── android/                         # Android-specific config
│   ├── app/build.gradle.kts
│   └── local.properties             # Android SDK path (auto-generated)
│
├── ios/                             # iOS-specific config (if needed)
│
├── test/                            # Unit tests
│   └── widget_test.dart
│
└── web/                             # Web support (optional)
```

### Key Files

- **`lib/main.dart`** — App initialization, theme, root navigation
- **`lib/utils/url.dart`** — API endpoint configuration (emulator vs device)
- **`lib/utils/session_manager.dart`** — JWT token persistence via SharedPreferences
- **`lib/views/quiz_page.dart`** — Main exam-taking interface
- **`lib/controllers/exam_controller.dart`** — Exam state management + auto-save logic
- **`lib/services/exam_service.dart`** — HTTP calls to backend for exam data

---

## Coding Standards

### Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Dart File | snake_case | `quiz_page.dart`, `exam_controller.dart` |
| Dart Class | PascalCase | `ExamController`, `QuizPage`, `CustomButton` |
| Dart Variable | camelCase | `currentExam`, `questionList`, `studentScore` |
| Dart Function | camelCase | `getMyExams()`, `startExam()`, `submitAnswer()` |
| Model Field | camelCase (Dart), snake_case (JSON) | Dart: `endDate`, JSON: `end_date` |
| Constant | UPPER_SNAKE or PascalCase | `API_TIMEOUT`, `Colors.PRIMARY` |

### JSON Serialization

All models must have `fromJson()` factory constructor to parse backend responses:

```dart
class Exam {
  final int examId;
  final String examName;
  final DateTime endDate;

  Exam({
    required this.examId,
    required this.examName,
    required this.endDate,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      examId: json['exam_id'],
      examName: json['exam_name'],
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
```

### State Management

- Use `StatefulWidget` + `setState()` for simple component state
- Use `Provider` or `Riverpod` for global app state (if added later)
- Persistent data (JWT token, user ID) → `SharedPreferences` via `SessionManager`

### HTTP Requests

All API calls use `http` package:

```dart
import 'package:http/http.dart' as http;
import '../utils/url.dart';

class ExamService {
  static Future<List<Exam>> getMyExams() async {
    final token = await SessionManager.getToken();
    final response = await http.get(
      Uri.parse('${Url.baseUrl}/student/my-exams'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return List<Exam>.from(
        jsonData['exams'].map((e) => Exam.fromJson(e))
      );
    } else {
      throw Exception('Failed to load exams');
    }
  }
}
```

### Best Practices

- **Async operations** → Use `FutureBuilder` or `async`/`await` in controller
- **Error handling** → Catch exceptions, show user-friendly error dialogs
- **Performance** → Minimize rebuilds with `const` constructors
- **Security** → Never hardcode credentials; use environment/config files
- **Logging** → Use `debugPrint()` for development debugging
| Function/Method | camelCase | `startExam()`, `submitAnswer()` |
| Variable | camelCase | `examList`, `isLoading` |
| Constant | camelCase or UPPER_SNAKE | `baseUrl`, `_port` |
| Widget | PascalCase | `ExamCard`, `QuestionPicker` |
| Model Field | camelCase (Dart) | `endDate`, `durationMinutes` |
| JSON Key | snake_case (API) | `end_date`, `duration_minutes` |

### Code Style

- **Architecture** — MVC + Provider: Models, Views, Controllers, Services, Providers (`ChangeNotifier`)
- **Models** — Data classes with `fromJson()` factory constructors for API response parsing
- **Controllers** — Orchestrate complex flows that span multiple services (e.g. `ExamController`)
- **Services** — HTTP calls to backend API endpoints; injected into providers/controllers
- **Providers** — App-wide state: `AuthProvider`, `ConnectivityProvider` (see `lib/providers/`)
- **Views** — UI widgets that read providers via `context.watch` / `context.read`
- **Widgets** — Reusable UI components grouped by purpose (`cards/`, `common/`, `dialogs/`, `home/`, `quiz/`)
- **Navigation** — `Navigator.push()` / `Navigator.pushReplacement()`
- **Error Handling** — Try/catch around API calls, `ScaffoldMessenger` for user-facing errors
- **Session** — JWT token stored via `flutter_secure_storage` and exposed through `SessionManager`
- **Config** — Backend URL via `--dart-define=API_BASE_URL=...` (see `lib/config/env.dart`)
- **Linter** — `flutter_lints` + `prefer_single_quotes`, `require_trailing_commas`

### Project Structure

```
lib/
├── main.dart                         # Bootstraps runApp; hosts MyHomePage (bottom nav)
├── app.dart                          # Root: MultiProvider + MaterialApp + SplashPage
├── config/
│   └── env.dart                      # Backend URL from --dart-define (API_BASE_URL)
├── controllers/
│   └── exam_controller.dart          # Orchestrates exam flows across services
├── models/
│   ├── user_model.dart               # User from API
│   ├── exam_model.dart               # Exam (questions, timer, etc.)
│   ├── exam_response_model.dart      # Response: GET /students/exams
│   ├── exam_result_response_model.dart   # Response: GET /exam-results/my-results
│   ├── start_exam_response_model.dart    # Response: POST /students/exams/start
│   ├── school_profile_model.dart     # School profile
│   └── quiz_model.dart               # Per-question model
├── providers/
│   ├── auth_provider.dart            # Auth status, login/logout, bootstrap
│   └── connectivity_provider.dart    # Periodic online/offline polling
├── services/
│   ├── auth_service.dart             # API: POST /auth/login, /auth/logout
│   ├── exam_service.dart             # API: students/exams/*, exam-results/*
│   ├── profile_service.dart          # API: /auth/me, /auth/profile, /auth/change-password
│   ├── school_profile_service.dart   # API: /school-profile
│   ├── time_service.dart             # Trusted server time for offline window checks
│   ├── offline_exam_storage.dart     # Local cache of exam data + pending answers
│   └── offline_sync_service.dart     # Re-sync queued answers / finishes
├── utils/
│   ├── session_manager.dart          # Secure JWT token storage wrapper
│   ├── page_transitions.dart         # Fade/slide route builders
│   └── helpers.dart                  # Date formatter, exam type helper
├── views/
│   ├── splash_page.dart              # Decides login vs. home based on auth bootstrap
│   ├── login_page.dart
│   ├── home_page.dart                # Tab 1: exam list
│   ├── history_page.dart             # Tab 2: history + scores
│   ├── profile_page.dart             # Tab 3: profile + logout
│   ├── quiz_page.dart                # Exam taking (timer, questions, navigation)
│   ├── quiz_essay_page.dart
│   ├── quiz_multiple_choice_page.dart
│   ├── quiz_picker.dart
│   ├── quiz_blocked_page.dart
│   └── quiz_end_page.dart
├── widgets/
│   ├── cards/                        # exam_card, history_card
│   ├── common/                       # error_state, loading_state, picker_item
│   ├── dialogs/                      # All *_dialog.dart
│   ├── home/                         # home_header, exam_list_section, navbar
│   └── quiz/                         # (reserved for split-out quiz subwidgets)
└── style/
    └── style.dart                    # Colors + theme

test/
├── config/env_test.dart
└── providers/auth_provider_test.dart # mocktail-based unit tests
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
