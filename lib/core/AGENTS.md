# Core Layer - AGENTS.md

## Overview
The `core` layer contains shared utilities, constants, error handling, and dependency injection used across all other layers. This is the foundation layer with no external dependencies except Flutter SDK and utility packages.

## Directory Structure
```
core/
├── constants/      # App-wide constants and configuration
├── errors/         # Failure classes for error handling
└── utils/          # Shared utilities (DI, theming, routing)
```

## Key Files

### `constants/app_constants.dart`
Centralized configuration for the entire app. **Never hardcode values elsewhere**.

```dart
class AppConstants {
  // API endpoints
  static const String quranApiBaseUrl = 'https://api.alquran.cloud/v1';
  static const String prayerTimesApiBaseUrl = 'https://api.aladhan.com/v1';
  
  // Quran data
  static const int totalSurahs = 114;
  static const int totalVerses = 6236;
  static const int totalPages = 604; // Mushaf mode
  
  // Cache config
  static const Duration cacheExpiry = Duration(days: 7);
  
  // Storage keys (SharedPreferences)
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLastReadSurah = 'last_read_surah';
  
  // Defaults
  static const String defaultReciter = 'ar.alafasy';
  static const String defaultTranslation = 'en.sahih';
}
```

**When adding new constants**:
1. Group logically (API, UI, Storage, etc.)
2. Use `static const` for compile-time constants
3. Prefix storage keys with `key` (e.g., `keyThemeMode`)

### `errors/failures.dart`
Defines all failure types returned in `Result<T>` pattern. **Never throw exceptions in use cases/repositories** - convert to `Failure`.

```dart
// Base class
abstract class Failure {
  final String message;
  final int? code;
  const Failure({required this.message, this.code});
}

// Network failures
class NetworkFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
class TimeoutFailure extends Failure { ... }

// Data failures
class CacheFailure extends Failure { ... }
class StorageFailure extends Failure { ... }

// Business logic failures
class InvalidInputFailure extends Failure { ... }
class QuranDataFailure extends Failure { ... }
class BookmarkFailure extends Failure { ... }
```

**Usage Pattern**:
```dart
// In repositories/use cases
try {
  final data = await api.fetchData();
  return Success(data);
} on NetworkException catch (e) {
  return ResultError(NetworkFailure(message: e.message));
} catch (e) {
  return ResultError(ServerFailure(message: 'Unexpected: $e'));
}
```

**When adding new failure types**:
1. Extend `Failure` base class
2. Group by category (Network, Cache, Business Logic)
3. Provide meaningful default messages
4. Include `code` for API error codes if applicable

### `utils/dependency_injection.dart`
Manual dependency injection container. Initializes all core dependencies in correct order.

```dart
class DependencyInjection {
  static bool _isInitialized = false;
  
  // Singletons
  static late QuranRepositoryInterface _quranRepository;
  static late GetSurahUseCase _getSurahUseCase;
  static late SurahProvider _surahProvider;
  
  static Future<void> init() async {
    // 1. External dependencies (HTTP, connectivity)
    _httpClient = http.Client();
    final connectivity = Connectivity();
    
    // 2. Data sources
    final remoteDataSource = QuranRemoteDataSource(client: _httpClient!);
    
    // 3. Repositories
    _quranRepository = QuranRepository(...);
    await _quranRepository.initialize(); // Open Hive boxes
    
    // 4. Use cases
    _getSurahUseCase = GetSurahUseCase(_quranRepository);
    
    // 5. Providers
    _surahProvider = SurahProvider(_getSurahUseCase);
    
    _isInitialized = true;
  }
  
  static QuranRepositoryInterface get quranRepository {
    _ensureInitialized();
    return _quranRepository;
  }
}
```

**Critical Rules**:
1. **Call `await DependencyInjection.init()` in `main()` before `runApp()`**
2. Initialize in dependency order: external → datasources → repositories → use cases → providers
3. Use getters with `_ensureInitialized()` check for lazy access
4. Provide factory methods for instances that need multiple copies (e.g., `createSurahProvider()`)

**When adding new dependencies**:
1. Add private static field: `static late MyClass _myDependency;`
2. Initialize in `init()` at correct position in dependency chain
3. Add public getter: `static MyClass get myDependency => _myDependency;`
4. If stateless, consider making the class itself static instead of DI

### `utils/app_theme.dart`
Material 3 theme configuration with dynamic color support and multiple presets.

```dart
enum AppThemeStyle {
  islamic('Islamic', FlexScheme.green, Colors.green),
  ocean('Ocean Blue', FlexScheme.blue, Colors.blue),
  sunset('Sunset', FlexScheme.amber, Colors.orange),
  // ... more presets
}

enum ArabicFontFamily {
  amiri('Amiri', 'Amiri'),
  scheherazade('Scheherazade New', 'Scheherazade New'),
  notoSansArabic('Noto Sans Arabic', 'Noto Sans Arabic'),
  // ... more fonts
}

class AppTheme {
  static ThemeData lightTheme({
    AppThemeStyle style = AppThemeStyle.islamic,
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
  }) {
    // Uses flex_color_scheme for Material 3 themes
    return FlexThemeData.light(
      scheme: style.flexScheme,
      textTheme: GoogleFonts.robotoTextTheme(...),
      // ... custom configurations
    );
  }
}
```

**Theme Features**:
- **Material 3** design system with `flex_color_scheme`
- **Dynamic color** support (adapts to system wallpaper on Android 12+)
- **Multiple presets**: Islamic (green), Ocean (blue), Sunset (orange), etc.
- **Arabic font switching**: Amiri, Scheherazade, Noto Sans Arabic, Cairo, Tajawal
- **Font scaling**: 0.7x - 2.0x for accessibility
- **Dark/Light mode** support

**Managed by**: `EnhancedThemeProvider` in `presentation/providers/`

**When customizing themes**:
1. Don't hardcode colors in widgets - use `Theme.of(context).colorScheme`
2. For Arabic text, use `arabicFont` parameter or read from provider
3. Test all presets + dark/light modes for consistency
4. Ensure WCAG contrast ratios (especially for text on colored backgrounds)

### `utils/route_observer.dart`
Custom route observer for analytics and lifecycle tracking (not critical for most development).

## Error Handling Strategy

### The Result Pattern
All data operations return `Result<T>` sealed class:

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T data; }
class ResultError<T> extends Result<T> { final Failure failure; }
```

**Why?**:
- Forces explicit error handling (no uncaught exceptions)
- Type-safe error states
- Consistent error handling across layers
- Easy to pattern match: `if (result is Success<T>) { ... }`

**Pattern in Use Cases**:
```dart
Future<Result<Surah>> execute(int surahNumber) async {
  // Validation
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(InvalidInputFailure(message: '...'));
  }
  
  // Call repository (already returns Result)
  final result = await repository.getSurah(surahNumber);
  
  // Apply business logic to success case
  if (result is Success<Surah>) {
    if (result.data.verses.isEmpty) {
      return ResultError(QuranDataFailure(message: '...'));
    }
    return Success(result.data);
  }
  
  return result; // Pass through error
}
```

**Pattern in Providers**:
```dart
Future<void> loadData() async {
  _setLoading(true);
  final result = await useCase.execute();
  
  if (result is Success<T>) {
    _data = result.data;
    _errorMessage = null;
  } else if (result is ResultError<T>) {
    _errorMessage = result.failure.message;
  }
  
  _setLoading(false);
  notifyListeners();
}
```

## Common Patterns

### 1. Adding a New Constant
```dart
// In app_constants.dart
class AppConstants {
  // Group with similar constants
  static const String keyNewFeature = 'new_feature_enabled';
  static const int newFeatureLimit = 10;
}

// Usage
final enabled = prefs.getBool(AppConstants.keyNewFeature) ?? false;
```

### 2. Adding a New Failure Type
```dart
// In failures.dart
class MyNewFailure extends Failure {
  const MyNewFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

// Usage in repository
return ResultError(MyNewFailure(message: 'Operation failed'));
```

### 3. Adding to Dependency Injection
```dart
// In dependency_injection.dart
class DependencyInjection {
  static late MyNewService _myNewService;
  
  static Future<void> init() async {
    // ... existing inits
    
    // Initialize new service
    _myNewService = MyNewService(dependency: _someDependency);
    await _myNewService.initialize();
  }
  
  static MyNewService get myNewService {
    _ensureInitialized();
    return _myNewService;
  }
}
```

## Theme Customization Guide

### Adding a New Theme Preset
```dart
// In app_theme.dart
enum AppThemeStyle {
  // ... existing presets
  myNewTheme('My Theme', FlexScheme.aquaBlue, Colors.cyan),
}
```

### Changing Arabic Font in UI
```dart
// In a screen/widget
final themeProvider = context.read<EnhancedThemeProvider>();
themeProvider.setArabicFont(ArabicFontFamily.scheherazade);
```

### Using Theme Colors
```dart
// ✅ CORRECT - Uses theme colors
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)

// ❌ WRONG - Hardcoded colors
Container(
  color: Colors.green, // Will break in other themes
  child: Text('Hello', style: TextStyle(fontSize: 18)),
)
```

## Testing Considerations

### Testing with DI
```dart
// In tests
setUp(() async {
  await DependencyInjection.init();
});

tearDown(() async {
  await DependencyInjection.dispose();
});
```

### Mocking Dependencies
For unit tests, consider creating a test-specific DI or using GetIt/Riverpod instead of manual DI.

## Migration Notes

### If Refactoring to GetIt/Riverpod
Current manual DI can be replaced with:
- **GetIt**: Service locator, similar pattern
- **Riverpod**: Modern provider system with compile-time safety
- **Injectable**: Code generation for DI

**Recommendation**: Keep manual DI for now (simpler for this app size). Consider GetIt if the app grows beyond 20+ dependencies.

---

**Related Documentation**:
- See `/AGENTS.md` for overall architecture
- See `lib/domain/AGENTS.md` for use case patterns
- See `lib/data/AGENTS.md` for repository implementation
