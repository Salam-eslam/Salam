# Core Utils - AGENTS.md

## Overview
This directory contains utility classes for app-wide concerns: dependency injection, theming, and route observation.

## Files

### 1. `dependency_injection.dart`
Manual dependency injection container for Clean Architecture.

**Purpose**: Initialize and provide singleton instances of repositories, use cases, and providers.

**Key Pattern**: Initialize dependencies in correct order (bottom-up):
1. External dependencies (HTTP client, Connectivity)
2. Data sources
3. Repositories
4. Use cases
5. Providers

**Full Structure**:
```dart
class DependencyInjection {
  static bool _isInitialized = false;
  
  // External resources
  static http.Client? _httpClient;
  
  // Core dependencies
  static late QuranRepositoryInterface _quranRepository;
  static late GetSurahUseCase _getSurahUseCase;
  static late ManageBookmarksUseCase _manageBookmarksUseCase;
  static late BookmarksProvider _bookmarksProvider;
  static late SurahProvider _surahProvider;
  
  static Future<void> init() async {
    // 1. External dependencies
    _httpClient = http.Client();
    final connectivity = Connectivity();
    
    // 2. Data sources
    final remoteDataSource = QuranRemoteDataSource(client: _httpClient!);
    
    // 3. Repository
    final repository = QuranRepository(
      remoteDataSource: remoteDataSource,
      connectivity: connectivity,
    );
    await repository.initialize(); // Open Hive boxes
    _quranRepository = repository;
    
    // 4. Use cases
    _getSurahUseCase = GetSurahUseCase(_quranRepository);
    _manageBookmarksUseCase = ManageBookmarksUseCase(_quranRepository);
    
    // 5. Providers
    _bookmarksProvider = BookmarksProvider(_manageBookmarksUseCase);
    _surahProvider = SurahProvider(_getSurahUseCase);
    
    _isInitialized = true;
  }
  
  // Getters with initialization check
  static QuranRepositoryInterface get quranRepository {
    _ensureInitialized();
    return _quranRepository;
  }
  
  static SurahProvider get surahProvider {
    _ensureInitialized();
    return _surahProvider;
  }
  
  // Factory methods for multiple instances
  static SurahProvider createSurahProvider() {
    _ensureInitialized();
    return SurahProvider(_getSurahUseCase);
  }
  
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('DependencyInjection not initialized. Call init() first.');
    }
  }
  
  static Future<void> dispose() async {
    _httpClient?.close();
    _httpClient = null;
    _isInitialized = false;
  }
}
```

**Usage in main()**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await DependencyInjection.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: DependencyInjection.surahProvider),
        ChangeNotifierProvider.value(value: DependencyInjection.bookmarksProvider),
      ],
      child: MyApp(),
    ),
  );
}
```

**Adding New Dependencies**:
```dart
// 1. Add private field
static late MyUseCase _myUseCase;
static late MyProvider _myProvider;

// 2. Initialize in init()
static Future<void> init() async {
  // ... existing init
  
  _myUseCase = MyUseCase(_quranRepository);
  _myProvider = MyProvider(_myUseCase);
}

// 3. Add getter
static MyProvider get myProvider {
  _ensureInitialized();
  return _myProvider;
}
```

**Critical Rules**:
- Always call `await DependencyInjection.init()` before `runApp()`
- Never instantiate use cases/repositories manually (always use DI)
- Initialize repository before use cases
- Factory methods for providers that need multiple instances

---

### 2. `app_theme.dart`
Material 3 theme configuration with multiple presets and dynamic color support.

**Key Enums**:

```dart
enum AppThemeStyle {
  islamic('Islamic', FlexScheme.green, Colors.green),
  ocean('Ocean Blue', FlexScheme.blue, Colors.blue),
  sunset('Sunset', FlexScheme.amber, Colors.orange),
  forest('Forest', FlexScheme.materialBaseline, Colors.teal),
  royal('Royal Purple', FlexScheme.deepPurple, Colors.deepPurple),
  elegant('Elegant Dark', FlexScheme.materialHc, Colors.blueGrey);
  
  const AppThemeStyle(this.name, this.flexScheme, this.primaryColor);
  final String name;
  final FlexScheme flexScheme;
  final Color primaryColor;
}

enum ArabicFontFamily {
  amiri('Amiri', 'Amiri'),
  scheherazade('Scheherazade New', 'Scheherazade New'),
  notoSansArabic('Noto Sans Arabic', 'Noto Sans Arabic'),
  cairo('Cairo', 'Cairo'),
  tajawal('Tajawal', 'Tajawal');
  
  const ArabicFontFamily(this.displayName, this.fontFamily);
  final String displayName;
  final String fontFamily;
}
```

**Main Class**:
```dart
class AppTheme {
  // Brand colors
  static const Color _primaryBlue = Color(0xFF667eea);
  static const Color _secondaryPurple = Color(0xFF764ba2);
  
  // Material 3 color schemes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: _primaryBlue,
    onPrimary: Colors.white,
    secondary: _secondaryPurple,
    // ... more colors
  );
  
  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF667eea),
    onPrimary: Color(0xFF000000),
    // ... more colors
  );
  
  // Theme builders
  static ThemeData lightTheme({
    AppThemeStyle style = AppThemeStyle.islamic,
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
    bool isHighContrast = false,
  }) {
    return FlexThemeData.light(
      scheme: style.flexScheme,
      textTheme: _getTextTheme(
        isArabic: false,
        arabicFont: arabicFont,
        fontScale: fontScale,
      ),
      useMaterial3: true,
      // ... more configuration
    );
  }
  
  static ThemeData darkTheme({...}) { /* Similar */ }
  
  static TextTheme arabicTextTheme({
    ArabicFontFamily arabicFont = ArabicFontFamily.cairo,
    double fontScale = 1.0,
  }) {
    return GoogleFonts.getTextTheme(
      arabicFont.fontFamily,
      _baseTextTheme.apply(fontSizeFactor: fontScale),
    );
  }
}
```

**Features**:
- **Material 3** design system
- **6 theme presets** (Islamic/green is default)
- **5 Arabic fonts** (Cairo is default)
- **Font scaling** 0.7x - 2.0x for accessibility
- **High contrast mode** for visually impaired users
- **Dynamic color** support (Android 12+ wallpaper colors)

**Usage**:
```dart
// In EnhancedThemeProvider
ThemeData get lightTheme => AppTheme.lightTheme(
  style: _themeStyle,
  arabicFont: _arabicFont,
  fontScale: _fontScale,
  isHighContrast: _isHighContrast,
);

// In widgets
Text(
  'بِسْمِ اللَّهِ',
  style: AppTheme.arabicTextTheme(
    arabicFont: ArabicFontFamily.scheherazade,
    fontScale: 1.2,
  ).headlineLarge,
)
```

**Typography Scale** (Material 3):
```dart
static const TextTheme _baseTextTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
);
```

**Adding New Theme Preset**:
```dart
// 1. Add to AppThemeStyle enum
enum AppThemeStyle {
  // ... existing
  myNewTheme('My Theme', FlexScheme.aquaBlue, Colors.cyan),
}

// 2. No code changes needed in AppTheme class (automatically handled)

// 3. Add to theme selector UI
DropdownButton<AppThemeStyle>(
  items: AppThemeStyle.values.map((style) {
    return DropdownMenuItem(value: style, child: Text(style.name));
  }).toList(),
  onChanged: (style) => themeProvider.setThemeStyle(style!),
)
```

**Adding New Arabic Font**:
```dart
// 1. Add font files to assets/fonts/
// 2. Update pubspec.yaml
fonts:
  - family: MyNewFont
    fonts:
      - asset: assets/fonts/MyNewFont-Regular.ttf

// 3. Add to ArabicFontFamily enum
enum ArabicFontFamily {
  // ... existing
  myNewFont('My New Font', 'MyNewFont'),
}
```

---

### 3. `route_observer.dart`
Custom route observer for analytics and lifecycle tracking.

**Purpose**: Track screen navigation for analytics, logging, or debugging.

**Implementation**:
```dart
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _logNavigation('Push', route.settings.name);
    }
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _logNavigation('Pop', route.settings.name);
    }
  }
  
  void _logNavigation(String action, String? routeName) {
    print('[$action] ${routeName ?? 'Unknown Route'}');
    // Send to analytics service
  }
}
```

**Usage in MaterialApp**:
```dart
MaterialApp(
  navigatorObservers: [AppRouteObserver()],
  // ... other config
)
```

**Use Cases**:
- Track screen views for analytics
- Debug navigation flow
- Monitor app usage patterns
- Implement screen time tracking

**Not Critical**: Can be removed if analytics not needed.

---

## Common Patterns

### Pattern 1: Accessing DI in Code
```dart
// In a screen or service
final repository = DependencyInjection.quranRepository;
final data = await repository.getSurah(1);
```

### Pattern 2: Theme in Widget
```dart
// Access theme colors
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)
```

### Pattern 3: Arabic Text Styling
```dart
Text(
  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  style: AppTheme.arabicTextTheme(
    arabicFont: context.read<EnhancedThemeProvider>().arabicFont,
    fontScale: 1.5,
  ).headlineMedium,
  textDirection: TextDirection.rtl,
)
```

## Testing

### Test DI Initialization
```dart
test('should initialize all dependencies', () async {
  await DependencyInjection.init();
  
  expect(DependencyInjection.quranRepository, isNotNull);
  expect(DependencyInjection.surahProvider, isNotNull);
});
```

### Mock DI for Tests
```dart
// Create test-specific DI or use GetIt for easier mocking
class TestDI {
  static late MockQuranRepository mockRepository;
  
  static Future<void> init() async {
    mockRepository = MockQuranRepository();
  }
}
```

## Migration Considerations

### To GetIt (Service Locator)
If the app grows, consider migrating to GetIt:

```dart
final getIt = GetIt.instance;

void setupDI() {
  // Singletons
  getIt.registerSingleton<http.Client>(http.Client());
  
  // Lazy singletons
  getIt.registerLazySingleton<QuranRepository>(() => QuranRepository(...));
  
  // Factories (new instance each time)
  getIt.registerFactory<SurahProvider>(() => SurahProvider(...));
}

// Usage
final provider = getIt<SurahProvider>();
```

### To Riverpod (Modern Provider)
For better testability and compile-time safety:

```dart
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(...);
});

final surahProvider = StateNotifierProvider<SurahNotifier, SurahState>((ref) {
  final repository = ref.watch(quranRepositoryProvider);
  return SurahNotifier(repository);
});
```

---

**Related Documentation**:
- See `lib/core/AGENTS.md` for core layer overview
- See `lib/domain/AGENTS.md` for use case structure
- See `lib/presentation/providers/AGENTS.md` for provider usage
