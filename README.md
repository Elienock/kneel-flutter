# QuickChurch - Production Grade Prayer & Event Tracker

A production-ready Flutter application for managing church prayer requests. Built with Clean Architecture principles, featuring offline-first data persistence, Material 3 design, and enterprise-grade code organization.

**Lead Developer:** Elienock Lubaya Mulumba

---

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Why Production-Ready?](#why-production-ready)
- [Screenshots](#screenshots)
- [Future Enhancements](#future-enhancements)
- [License](#license)

---

## Project Overview

QuickChurch enables church communities to share, track, and manage prayer requests seamlessly. The app provides a beautiful, intuitive interface for submitting prayers, tracking their status, and celebrating answered prayers—all while working completely offline.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Prayer Management** | Create, view, update, and delete prayer requests |
| **Priority Levels** | Categorize prayers as Low, Medium, High, or Urgent |
| **Status Tracking** | Mark prayers as Active, Answered, or Archived |
| **Privacy Controls** | Option to keep prayers private |
| **Tagging System** | Organize prayers with custom tags |
| **Prayer Counter** | Track how many times a prayer has been prayed |
| **Offline Support** | Full functionality without internet connection |
| **Dark Mode** | High-contrast dark theme with system preference |
| **Pull-to-Refresh** | Intuitive gesture-based refresh |
| **Swipe-to-Delete** | Quick deletion with confirmation dialog |
| **Staggered Animations** | Premium feel with cascading card animations |
| **Shimmer Loading** | Elegant loading placeholders |

---

## Tech Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **Framework** | Flutter 3.x | Cross-platform mobile development |
| **Architecture** | Clean Architecture | Separation of concerns, testability |
| **State Management** | flutter_bloc (Cubit) | Predictable state management |
| **Dependency Injection** | GetIt + Injectable | Service location with code generation |
| **Local Storage** | Hive | Fast, lightweight NoSQL database |
| **Code Generation** | build_runner | Automated boilerplate generation |
| **UI/UX** | Material 3 | Modern, accessible design system |

---

## Architecture

QuickChurch follows **Clean Architecture** principles, organizing code into three distinct layers with clear boundaries and dependencies flowing inward.

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Pages     │  │   Widgets   │  │   Cubit/States      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │  Use Cases  │  │  Repository Interface│ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Models    │  │ Data Sources│  │  Repository Impl    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### Domain Layer (Business Logic)
The innermost layer containing enterprise business rules with **zero dependencies** on frameworks.

- **Entities** - Pure Dart classes representing core business objects (`Prayer`)
- **Repositories** - Abstract interfaces defining data contracts (`IPrayerRepository`)
- **Use Cases** - Single-responsibility business operations (`GetPrayers`, `AddPrayer`, `DeletePrayer`)

#### Data Layer (Data Access)
Implements repository interfaces and handles all data operations.

- **Models** - DTOs with serialization logic and Hive annotations (`PrayerModel`)
- **Data Sources** - Handles actual storage operations (`PrayerLocalDataSource`)
- **Repositories** - Concrete implementations coordinating data sources (`PrayerRepositoryImpl`)

#### Presentation Layer (UI)
Contains all UI-related code and state management.

- **Cubit** - Manages UI state and coordinates use cases (`PrayerCubit`)
- **States** - Immutable state classes using Dart 3 sealed classes (`PrayerState`)
- **Pages** - Full-screen widgets (`PrayerListPage`)
- **Widgets** - Reusable UI components (`PrayerCard`, `AddPrayerDialog`, `EmptyStateWidget`)

### Data Flow

```
User Interaction
       │
       ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Cubit    │───▶│   UseCase   │───▶│  Repository │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                      │
       │                                      ▼
       │                              ┌─────────────┐
       │                              │ DataSource  │
       │                              └─────────────┘
       │                                      │
       │                                      ▼
       │                              ┌─────────────┐
       │                              │    Hive     │
       │                              └─────────────┘
       │                                      │
       ▼                                      │
┌─────────────┐◀──────────────────────────────┘
│  UI Update  │
└─────────────┘
```

---

## Project Structure

```
quick_church/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── injection.dart                 # DI configuration
│   ├── injection.config.dart          # Generated DI code
│   │
│   ├── core/
│   │   ├── di/
│   │   │   └── register_module.dart   # Third-party DI registrations
│   │   ├── error/
│   │   │   ├── exceptions.dart        # Data layer exceptions
│   │   │   └── failures.dart          # Domain layer failures
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Material 3 theming
│   │   └── usecases/
│   │       └── usecase.dart           # Base use case class
│   │
│   └── features/
│       └── prayer/
│           ├── domain/
│           │   ├── entities/
│           │   │   └── prayer.dart
│           │   ├── repositories/
│           │   │   └── i_prayer_repository.dart
│           │   └── usecases/
│           │       ├── add_prayer.dart
│           │       ├── delete_prayer.dart
│           │       └── get_prayers.dart
│           │
│           ├── data/
│           │   ├── datasources/
│           │   │   └── prayer_local_data_source.dart
│           │   ├── models/
│           │   │   ├── prayer_model.dart
│           │   │   └── prayer_model.g.dart
│           │   └── repositories/
│           │       └── prayer_repository_impl.dart
│           │
│           └── presentation/
│               ├── bloc/
│               │   ├── prayer_cubit.dart
│               │   └── prayer_state.dart
│               ├── pages/
│               │   └── prayer_list_page.dart
│               └── widgets/
│                   ├── add_prayer_dialog.dart
│                   ├── empty_state.dart
│                   ├── prayer_card.dart
│                   └── shimmer_loading.dart
│
├── assets/
│   └── icon/
│       └── app_icon.png
│
├── android/                           # Android platform files
├── ios/                               # iOS platform files
├── test/                              # Unit and widget tests
├── pubspec.yaml                       # Dependencies
├── LICENSE                            # MIT License
└── README.md                          # Documentation
```

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / VS Code
- Android device or emulator

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/elienock/quick_church.git
cd quick_church

# 2. Install dependencies
flutter pub get

# 3. Generate code (Hive adapters + DI config)
dart run build_runner build --delete-conflicting-outputs

# 4. Generate splash screen
dart run flutter_native_splash:create

# 5. Generate app icons (requires assets/icon/app_icon.png)
dart run flutter_launcher_icons

# 6. Run the app
flutter run
```

---

## Why Production-Ready?

### 1. Error Handling with Failures
Instead of throwing exceptions across layer boundaries, the app uses a structured `Failure` class hierarchy:

```dart
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  // ...
}

class CacheFailure extends Failure { }
class ValidationFailure extends Failure { }
```

### 2. Separation of Concerns
Each layer has a single responsibility:
- **Domain** knows nothing about Flutter or databases
- **Data** handles all persistence logic
- **Presentation** only deals with UI and state

### 3. Dependency Injection
All dependencies are injected, making the code:
- **Testable** - Easy to mock dependencies
- **Maintainable** - Single source of truth for object creation
- **Scalable** - Add new features without modifying existing code

### 4. Immutable State Management
Using sealed classes ensures exhaustive pattern matching:

```dart
sealed class PrayerState extends Equatable { }
final class PrayerInitial extends PrayerState { }
final class PrayerLoading extends PrayerState { }
final class PrayerLoaded extends PrayerState { }
final class PrayerError extends PrayerState { }
```

### 5. Offline-First Architecture
Hive provides fast, reliable local storage that works without network connectivity.

### 6. Code Generation
Reduces boilerplate and human error through:
- `injectable_generator` for DI
- `hive_generator` for type adapters

---

## Screenshots

| Light Mode | Dark Mode |
|------------|-----------|
| Prayer List | Prayer List Dark |
| Add Prayer Dialog | Empty State |

---

## Future Enhancements

- [ ] Firebase Cloud Sync
- [ ] Push Notifications for Prayer Reminders
- [ ] Community Sharing Features
- [ ] Prayer Groups and Categories
- [ ] Statistics and Insights Dashboard
- [ ] Multi-language Support (i18n)
- [ ] Biometric Authentication
- [ ] Export/Import Prayers

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with Flutter and Clean Architecture principles.**

© 2026 Elienock Lubaya Mulumba. All rights reserved.
