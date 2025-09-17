# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "南哪课表" (NJU Class Schedule), a Material Design course schedule app for Nanjing University students on Android/iOS platforms. The app allows students to import course schedules from NJU's educational systems and manage their class timetables.

## Development Commands

Since Flutter CLI is not available in this environment, use these development patterns:

### Common Development Tasks
- **Build**: Standard Flutter commands would be `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Run**: `flutter run` for development
- **Test**: `flutter test` to run unit tests
- **Analyze**: `flutter analyze` for static analysis
- **Format**: `flutter format lib/` to format Dart code

### Linting and CI
- Uses `flutter_lints` package for code analysis (configured in `analysis_options.yaml`)
- Danger CI integration with Ruby gems for automated code review
- Analysis options disable some rules: `file_names`, `avoid_types_as_parameter_names`, `constant_identifier_names`

## Architecture

### MVP Pattern
The app follows the Model-View-Presenter (MVP) architectural pattern:
- **Models**: Data classes in `lib/Models/` (CourseModel, CourseTableModel, LectureModel, ScheduleModel)
- **Views**: UI components in `lib/Pages/` with corresponding View classes
- **Presenters**: Business logic in files like `CourseTablePresenter.dart`, `AddCoursePresenter.dart`

### State Management
- Uses `scoped_model` package for state management
- Central state in `lib/Utils/States/MainState.dart` which combines multiple state models:
  - `ThemeStateModel` - Theme and appearance
  - `ClassTableStateModel` - Course table data
  - `WeekStateModel` - Week selection
  - `FlagStateModel` - Feature flags
  - `ConfigStateModel` - App configuration

### Key Directories
- `lib/Pages/` - Main UI screens (CourseTable, AddCourse, Import, Settings, etc.)
- `lib/Components/` - Reusable UI components (Dialog, Toast, Separator)
- `lib/Models/` - Data models and database helpers
- `lib/Utils/` - Utilities for parsing, HTTP, state management
- `lib/Resources/` - Constants, themes, colors, configuration
- `api/` - Backend configuration files for different universities

## Data Layer

### Database
- Uses SQLite via `sqflite` package
- Database helper in `lib/Models/Db/DbHelper.dart`
- Course data stored in local SQLite database

### Course Import Systems
The app supports importing from multiple university systems:
- NJU JW (教务) system via web scraping
- NJU XK (选课) system  
- Other universities (SEU, SJTU, THU) with parsers in `api/tools/`

### HTML Parsing
- `lib/Utils/CourseParser.dart` - Parses NJU JW system HTML
- `lib/Utils/CourseParserXK.dart` - Parses NJU XK system HTML
- Uses regex patterns to extract course time, week, and location data

## Key Configuration

### App Constants
- `lib/Resources/Config.dart` contains:
  - Max classes per day: 13
  - Max weeks per semester: 25  
  - Default semester weeks: 17
  - University system URLs and scraping configs

### Localization
- Supports Chinese (zh_CN) and English (en)
- Localization files in `lib/l10n/`
- Generated files in `lib/generated/`

### Analytics
- Integrated with Umeng SDK for analytics
- Custom Umeng plugin in `lib/Libs/umeng_common_sdk/`

## Dependencies

### Core Flutter Packages
- `scoped_model` - State management
- `sqflite` - SQLite database
- `shared_preferences` - Local storage
- `dio` - HTTP networking

### UI Packages  
- `flutter_swiper_null_safety_flutter3` - Swiper component
- `azlistview` - A-Z list views
- `flutter_html` - HTML rendering
- `qr_flutter` / `qr_code_scanner` - QR code functionality

### Platform Integration
- `webview_flutter` - Web view for login systems
- `url_launcher` - Open external URLs
- `image_picker` - Image selection
- `device_calendar` - Calendar integration
- `in_app_review` - App store reviews

## Testing

Tests are located in `test/` directory:
- Unit tests for course parsers
- Widget tests for UI components  
- Test HTML files for parser validation

## University Adaptation

The current branch `seu-schedule-adaption` appears to be adapting the app for Southeast University (SEU). The app architecture supports multiple universities through:
- University-specific parsers in `api/tools/`
- Configurable URLs and scraping logic in `Config.dart`
- Modular import system in `lib/Pages/Import/`