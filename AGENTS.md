# AGENTS.md - Salam Quran App

## Project Overview
**Salam** is a comprehensive Islamic mobile application built with **Flutter 3.0+** featuring Quran reading, prayer times, AI assistant (gpt-4.1), and Islamic tools. The project follows **Clean Architecture** principles with strict layer separation and uses **Provider** for state management.

## Architecture Overview

### Clean Architecture Layers
```
lib/
├── core/           # Shared utilities, constants, error handling
├── domain/         # Business logic (entities, use cases, repository interfaces)
├── data/           # Data implementation (repositories, data sources, models)
├── presentation/   # UI (screens, widgets, providers)
└── services/       # External integrations (AI, notifications, audio, prayer times)
```

**Key Principle**: Dependencies flow inward. Domain layer has NO dependencies on outer layers.
- `domain/` → Pure Dart business logic
- `data/` → Implements domain interfaces, handles API/cache
- `presentation/` → Depends on domain use cases via providers
- `services/` → External integrations, used by data/presentation layers

## Critical Patterns

### 1. Result Pattern for Error Handling
All repository methods return `Result<T>` instead of throwing exceptions:

```dart
// domain/repositories/quran_repository_interface.dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T data; }
class ResultError<T> extends Result<T> { final Failure failure; }

// Usage in use cases
Future<Result<Surah>> execute(int surahNumber) async {
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(InvalidInputFailure(message: '...'));
  }
  return await repository.getSurah(surahNumber);
}
```

### 2. Dependency Injection Pattern
Manual DI container in `core/utils/dependency_injection.dart`:

```dart
class DependencyInjection {
  static Future<void> init() async {
    // Initialize in order: client → datasource → repository → usecase → provider
    _httpClient = http.Client();
    final remoteDataSource = QuranRemoteDataSource(client: _httpClient!);
    _quranRepository = QuranRepository(...);
    _getSurahUseCase = GetSurahUseCase(_quranRepository);
    _surahProvider = SurahProvider(_getSurahUseCase);
  }
  static SurahProvider get surahProvider => _surahProvider;
}
```

**Usage**: Call `await DependencyInjection.init()` in `main()` before runApp. Access singletons via `DependencyInjection.surahProvider`.

### 3. Offline-First with Hive Caching
Three-tier caching strategy (see `data/repositories/quran_repository.dart`):

```dart
Future<Result<Surah>> getSurah(int surahNumber) async {
  // 1. Check Hive cache
  final cached = _surahBox.get(surahNumber);
  if (cached != null && !cached.isExpired) {
    return Success(_convertCachedSurahToEntity(cached));
  }
  
  // 2. Check network connectivity
  if (!await _hasInternetConnection) {
    return cached != null 
      ? Success(_convertCachedSurahToEntity(cached)) // Return expired cache
      : ResultError(NetworkFailure(...));
  }
  
  // 3. Fetch from API and cache
  final data = await remoteDataSource.getSurah(surahNumber);
  await _surahBox.put(surahNumber, _convertSurahToCached(data));
  return Success(data);
}
```

**Hive Boxes**: Initialize in repository constructor via `Hive.openBox<T>()`. Models need `@HiveType()` and run `flutter packages pub run build_runner build`.

### 4. Provider State Management
Providers wrap use cases and expose UI state:

```dart
// presentation/providers/surah_provider.dart
class SurahProvider with ChangeNotifier {
  final GetSurahUseCase _getSurahUseCase;
  
  Future<bool> loadSurah(int surahNumber) async {
    _setLoading(true);
    final result = await _getSurahUseCase.execute(surahNumber);
    
    if (result is Success<Surah>) {
      _currentSurah = result.data;
      _setLoading(false);
      return true;
    } else if (result is ResultError<Surah>) {
      _setError(result.failure.message);
      _setLoading(false);
      return false;
    }
  }
}
```

**Provider Setup**: Registered in `main.dart` MultiProvider. Access via `context.read<T>()` or `Provider.of<T>(context)`.

## Development Workflows

### Running the App
```bash
flutter pub get                # Install dependencies
flutter run                    # Run on connected device/emulator
flutter run -d macos           # Run on macOS
flutter run --release          # Release build for testing
```

### Code Generation (Required After Model Changes)
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
# Run this after adding/modifying Hive models with @HiveType
```

### Environment Setup
Create `.env` in project root with:
```env
OPENAI_API_KEY=sk-...          # Required for AI assistant
```
**Never commit .env to git**. It's in `.gitignore`.

### Testing
```bash
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run specific test
```

## Key Constants & Configuration

### API Endpoints (core/constants/app_constants.dart)
```dart
quranApiBaseUrl = 'https://api.alquran.cloud/v1'
prayerTimesApiBaseUrl = 'https://api.aladhan.com/v1'
audioBaseUrl = 'https://cdn.islamic.network/quran/audio'
```

### Storage Keys (SharedPreferences & Hive)
- Hive boxes: `surahs`, `bookmarks`, `reading_progress`
- SharedPreferences: `onboarding_completed`, `theme_mode`, `last_read_surah`

### Quran Data Constants
- Total Surahs: 114
- Total Verses: 6236
- Total Pages: 604 (Mushaf mode)

## Service Layer Patterns

### 1. Islamic AI Service (gpt-4.1)
```dart
// services/islamic_ai_service.dart
class IslamicAIService {
  static const String _systemPrompt = '''
  You are an Islamic knowledge assistant...
  ONLY answer questions related to Quran, Hadith, Fiqh...
  ''';
  
  Future<AIResponse> askQuestion(String question) async {
    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-4.1-mini-2025-04-14",
      messages: [system(_systemPrompt), user(question)],
      temperature: 0.3,
    );
  }
}
```
**Critical**: AI is constrained to Islamic topics only. System prompt cannot be overridden by users.

### 2. Prayer Notification Service
```dart
// services/prayer_notification_service.dart
await PrayerNotificationService.initialize();  // Call in main()
await PrayerNotificationService.scheduleAllPrayerNotifications(prayerTimes);
await PrayerNotificationService.scheduleDailyAyahNotification();
```
Uses `flutter_local_notifications` + `timezone`. Requires notification permissions via `permission_handler`.

### 3. Auto Cache Service
Background caching for popular surahs (Al-Fatiha, Al-Baqarah, etc.):
```dart
// Called in main() after 2 second delay
AutoCacheService.cacheCommonSurahs();
```
Stores in SharedPreferences for permanent offline access.

## Common Pitfalls & Solutions

### 1. Hive Adapters Not Registered
**Error**: `Cannot read, unknown type`
**Solution**: Register adapters in `main()` before `runApp()`:
```dart
Hive.registerAdapter(CachedSurahAdapter());
Hive.registerAdapter(BookmarkAdapter());
```

### 2. Provider Not Found
**Error**: `Could not find the correct Provider<T>`
**Solution**: Ensure provider is registered in `main.dart` MultiProvider and context has access to it.

### 3. Result Pattern Misuse
**Wrong**: `throw Exception()` in use cases/repositories
**Right**: Return `ResultError(Failure())`. Catch exceptions at repository boundary and convert to `Result`.

### 4. Breaking Layer Boundaries
**Wrong**: Importing `presentation/` in `domain/`
**Right**: Domain imports NOTHING from outer layers. Data/Presentation depend on domain interfaces.

### 5. Environment Variable Missing
**Error**: `OpenAI API key not found`
**Solution**: Create `.env` with `OPENAI_API_KEY=sk-...` and ensure `flutter_dotenv` loads it in `main()`.

## File Naming Conventions

- **Entities**: `surah_entity.dart` (domain layer, pure business objects)
- **Models**: `cached_surah.dart` (data layer, with JSON/Hive serialization)
- **Use Cases**: `get_surah_usecase.dart` (domain layer)
- **Repositories**: `quran_repository.dart` (implementation), `quran_repository_interface.dart` (contract)
- **Providers**: `surah_provider.dart` (presentation layer)
- **Services**: `islamic_ai_service.dart` (external integrations)
- **Screens**: `surah_reader.dart` (presentation/screens)
- **Widgets**: `quran_page_widget.dart` (presentation/widgets)

## Material 3 Theming

Uses `EnhancedThemeProvider` with:
- Dynamic color support (`dynamic_color` package)
- Multiple theme presets (Islamic, Modern, Elegant)
- Dark/Light mode support
- Custom Arabic font scaling (14-32pt)

**Access theme**: `context.read<EnhancedThemeProvider>()`

## Accessibility Features

- Text-to-Speech (Arabic & English) via `flutter_tts`
- Screen reader support with semantic labels
- Adjustable font sizes (0.7x - 2.0x scale)
- High contrast mode support
- Brightness control via `screen_brightness`

**Initialize**: `await AccessibilityService().initialize()` in `main()`

## Integration Points

### External APIs
1. **Quran API**: api.alquran.cloud (Quran text, translations, tafsir)
2. **Prayer Times API**: api.aladhan.com (location-based prayer times)
3. **Audio CDN**: cdn.islamic.network (verse-by-verse recitations)
4. **OpenAI API**: GPT-4 for Islamic Q&A

### Flutter Packages (Key Dependencies)
- `provider: ^6.1.2` - State management
- `hive: ^2.2.3` + `hive_flutter` - Local storage
- `dio: ^5.3.2` - HTTP client (alternative to http)
- `dart_openai: ^5.1.0` - OpenAI API wrapper
- `flutter_local_notifications: ^17.2.2` - Push notifications
- `flutter_qiblah: ^2.2.0` - Qibla direction
- `geolocator: ^9.0.0` - Location services
- `audioplayers: ^6.1.0` - Audio playback

## When Adding New Features

### Adding a New Entity/Model
1. Create entity in `domain/entities/my_entity.dart` (pure Dart class)
2. Create model in `data/models/my_model.dart` with `fromJson()` / `toJson()`
3. If Hive storage needed: Add `@HiveType()`, `@HiveField()`, run build_runner
4. Register Hive adapter in `main()`

### Adding a New Use Case
1. Create in `domain/usecases/my_usecase.dart`
2. Inject repository interface via constructor
3. Implement `execute()` method with validation and business logic
4. Return `Result<T>` for error handling

### Adding a New Provider
1. Create in `presentation/providers/my_provider.dart`
2. Extend `ChangeNotifier`
3. Inject use case(s) via constructor
4. Call `notifyListeners()` after state changes
5. Register in `main.dart` MultiProvider

### Adding a New Service
1. Create in `services/my_service.dart`
2. Make static class or singleton if stateful
3. Initialize in `main()` or lazy load
4. Document any required permissions/setup

## Build & Release

### Android
```bash
flutter build apk --release       # APK for sideloading
flutter build appbundle --release # AAB for Play Store
```

### iOS
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode for archiving
```

### Configuration Files
- Android: `android/app/build.gradle.kts`, `AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`, `ios/Runner.xcodeproj`
- App icons: `flutter_launcher_icons` in `pubspec.yaml`

## Project-Specific Gotchas

1. **Mushaf Mode**: Quran is displayed by page (604 pages) not surah. Data comes from `quran_page_data.dart`.
2. **Bismillah Handling**: Surah 1 (Al-Fatiha) and Surah 9 (At-Tawbah) have special Bismillah rules.
3. **Verse Numbering**: 1-indexed in API but sometimes 0-indexed in UI. Check context.
4. **Audio Streaming**: Uses `audioplayers` with CDN URLs. Cache audio metadata, not files.
5. **Prayer Time Calculation**: Depends on geolocation + calculation method (see `prayer_notification_service.dart`).
6. **Translation Keys**: Format is `{language}.{translator}` (e.g., `en.sahih`, `ar.muyassar`).
7. **Reciter Keys**: Format is `{language}.{reciter}` (e.g., `ar.alafasy`, `ar.abdulbasit`).

## Documentation Structure

- `/docs/todo.md` - Feature backlog and known issues
- `/codefetch/codebase.md` - Additional codebase documentation
- `/README.md` - User-facing project overview
- `AGENTS.md` (this file) - AI agent guide

## Folder-Specific Documentation

For detailed information about each layer, see:
- `lib/core/AGENTS.md` - Core utilities, error handling, DI
- `lib/domain/AGENTS.md` - Business logic, entities, use cases
- `lib/data/AGENTS.md` - Data layer, caching, API integration
- `lib/presentation/AGENTS.md` - UI components, providers, screens
- `lib/services/AGENTS.md` - External service integrations

---

**Last Updated**: November 2025
**Flutter Version**: >=3.0.0
**Dart Version**: >=3.0.0
