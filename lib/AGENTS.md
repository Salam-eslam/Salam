# lib/ Directory - AGENTS.md

## Overview
The `lib/` directory is the **main source code root** for the Salam Quran Flutter application. It follows **Clean Architecture** principles with clear separation of concerns across domain, data, and presentation layers.

## Directory Structure

```
lib/
├── main.dart                    # App entry point, initialization, providers
├── core/                        # Shared utilities (constants, errors, DI, theme)
├── domain/                      # Business logic (entities, use cases, interfaces)
├── data/                        # Data implementation (repositories, models, sources)
├── presentation/                # UI layer (screens, widgets, providers)
└── services/                    # External integrations (AI, notifications, audio)
```

## main.dart - Application Bootstrap

**Purpose**: Initialize app dependencies, register providers, configure Material app.

### Initialization Sequence

**1. Environment Setup**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file (contains OPENAI_API_KEY)
  await dotenv.load(fileName: ".env");
```

**2. Hive Initialization**:
```dart
  // Initialize Hive for local caching
  await Hive.initFlutter();
  
  // Register all Hive adapters (MUST be done before opening boxes)
  Hive.registerAdapter(CachedSurahAdapter());
  Hive.registerAdapter(CachedAyahAdapter());
  Hive.registerAdapter(BookmarkAdapter());
  Hive.registerAdapter(PageProgressAdapter());
```

**Critical**: All Hive adapters MUST be registered before any `Hive.openBox()` calls. Add new adapters here when creating new cached models.

**3. Dependency Injection**:
```dart
  // Initialize DI container (repositories, use cases, providers)
  await DependencyInjection.init();
```

See `lib/core/utils/dependency_injection.dart` for initialization details. This creates singletons for:
- HTTP client
- Data sources (QuranRemoteDataSource)
- Repositories (QuranRepository)
- Use cases (GetSurahUseCase, ManageBookmarksUseCase)
- Providers (SurahProvider, BookmarksProvider)

**4. Background Services**:
```dart
  // Cache popular surahs after 2 seconds
  _initializeCache();
  
  // Initialize prayer notifications after 3 seconds
  _initializeServices();
```

**5. Provider Setup**:
```dart
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferenceSettingsProvider()),
        ChangeNotifierProvider.value(value: DependencyInjection.bookmarksProvider),
        ChangeNotifierProvider.value(value: DependencyInjection.surahProvider),
        ChangeNotifierProvider(create: (_) => ReadingProgressProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
        ChangeNotifierProvider(
          create: (_) => QuranPageProvider(DependencyInjection.quranRepository),
        ),
        ChangeNotifierProvider(create: (_) => PageProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
```

**Provider Pattern**: Mix of `.value` (for DI singletons) and `create` (for new instances).

---

## MyApp Widget - Material App Configuration

```dart
class MyApp extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quran App - القرآن الكريم',
          
          // Material 3 theming
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Localization (5 languages supported)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),  // English (default)
            Locale('ar', ''),  // Arabic
            Locale('ur', ''),  // Urdu
            Locale('fr', ''),  // French
            Locale('id', ''),  // Indonesian
          ],
          
          home: const AppInitializer(),
        );
      },
    );
  }
}
```

**Theme System**: Material 3 with 6 theme presets (Islamic, Ocean, Sunset, Forest, Royal, Elegant). Supports dynamic colors on Android 12+.

**Localization**: Ready for 5 languages. Translation strings need to be added via Flutter intl package.

---

## AppInitializer - Onboarding Flow

**Purpose**: Show splash screen, check onboarding status, route to main app or onboarding.

```dart
class AppInitializer extends StatefulWidget {
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showOnboarding = false;
  
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }
  
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    
    await Future.delayed(const Duration(seconds: 1)); // Splash delay
    
    setState(() {
      _showOnboarding = !hasCompletedOnboarding;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSplashScreen();
    }
    
    return _showOnboarding ? const OnboardingScreen() : const MainScreen();
  }
}
```

**Flow**:
1. Show splash screen (1 second)
2. Check `onboarding_completed` in SharedPreferences
3. Route to OnboardingScreen (first launch) or MainScreen (returning user)

**Splash Screen**: Displays app icon + loading spinner + "Quran App" text.

---

## Background Initialization

### Cache Service
```dart
void _initializeCache() {
  Future.delayed(const Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}
```

**Purpose**: Preload frequently read surahs for offline access.
- Al-Fatihah (1)
- Al-Baqarah (2)
- Ya-Sin (36)
- Ar-Rahman (55)
- Al-Waqi'ah (56)
- Al-Mulk (67)

**Delay**: 2 seconds after app launch to avoid blocking UI.

### Services Initialization
```dart
void _initializeServices() {
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      await PrayerNotificationService.initialize();
      await PrayerNotificationService.scheduleDailyAyahNotification();
      await AccessibilityService().initialize();
    } catch (e) {
      // Silently fail - services are non-critical
    }
  });
}
```

**Services Started**:
1. **PrayerNotificationService**: Schedule prayer time notifications
2. **Daily Ayah**: Daily verse notification (default 8:00 AM)
3. **AccessibilityService**: Text-to-speech, screen reader support

**Delay**: 3 seconds to ensure app is fully loaded.

---

## Architecture Layers

### 1. Core Layer (`lib/core/`)
**Purpose**: Shared utilities and infrastructure.

**Contents**:
- `constants/` - API URLs, Quran constants, cache config
- `errors/` - Failure hierarchy (NetworkFailure, CacheFailure, etc.)
- `utils/` - Dependency injection, theming, route observer

**Dependencies**: None (innermost layer)

**Documentation**: See `lib/core/AGENTS.md`

---

### 2. Domain Layer (`lib/domain/`)
**Purpose**: Business logic and rules (framework-agnostic).

**Contents**:
- `entities/` - Pure Dart business objects (Surah, Verse, PrayerTimes, etc.)
- `usecases/` - Business operations (GetSurahUseCase, ManageBookmarksUseCase)
- `repositories/` - Repository interfaces (contracts only, no implementation)

**Dependencies**: None (pure Dart, zero external dependencies)

**Key Pattern**: `Result<T>` sealed class for error handling (no exceptions)

**Documentation**: See `lib/domain/AGENTS.md`

---

### 3. Data Layer (`lib/data/`)
**Purpose**: Data fetching, caching, and repository implementations.

**Contents**:
- `datasources/` - API clients (QuranRemoteDataSource, QuranPageData)
- `models/` - Data transfer objects with Hive annotations
- `repositories/` - Repository implementations (QuranRepository)

**Dependencies**: domain layer interfaces, HTTP, Hive

**Key Pattern**: Three-tier caching (fresh cache → expired cache → API)

**Documentation**: See `lib/data/AGENTS.md`

---

### 4. Presentation Layer (`lib/presentation/`)
**Purpose**: UI and state management.

**Contents**:
- `providers/` - ChangeNotifier state managers (9 providers)
- `screens/` - Full-page widgets (17 screens)
- `widgets/` - Reusable UI components (4 widgets)

**Dependencies**: domain use cases (via providers), Flutter framework

**Key Pattern**: Provider pattern for state management

**Documentation**: See `lib/presentation/AGENTS.md`

---

### 5. Services Layer (`lib/services/`)
**Purpose**: External integrations and platform services.

**Contents**:
- `islamic_ai_service.dart` - GPT-4 integration
- `prayer_notification_service.dart` - Prayer time notifications
- `audio_player_service.dart` - Verse-by-verse audio playback
- `accessibility_service.dart` - TTS and screen reader
- `auto_cache_service.dart` - Background caching
- `islamic_calendar_service.dart` - Hijri calendar
- Plus 5 more specialized services

**Dependencies**: External APIs, platform-specific code

**Documentation**: See `lib/services/AGENTS.md`

---

## Dependency Flow

```
┌─────────────────────────────────────────┐
│           Presentation                  │ ← User interaction
│  (screens, widgets, providers)          │
└────────────────┬────────────────────────┘
                 │ depends on
                 ↓
┌─────────────────────────────────────────┐
│             Domain                      │ ← Business logic
│  (entities, use cases, interfaces)      │
└────────────────┬────────────────────────┘
                 │ implemented by
                 ↓
┌─────────────────────────────────────────┐
│              Data                       │ ← Data fetching
│  (repositories, models, data sources)   │
└────────────────┬────────────────────────┘
                 │ uses
                 ↓
┌─────────────────────────────────────────┐
│            Services                     │ ← External APIs
│  (AI, notifications, audio, etc.)      │
└─────────────────────────────────────────┘

       Core utilities used by all layers
```

**Critical Rule**: Dependencies flow **inward**. Domain layer has ZERO dependencies on outer layers.

---

## Environment Variables (.env)

**Required**:
```env
OPENAI_API_KEY=sk-...
```

**Location**: Project root `/Salam/.env`

**Loading**: `await dotenv.load(fileName: ".env");` in main()

**Usage**:
```dart
final apiKey = dotenv.env['OPENAI_API_KEY'];
if (apiKey == null) {
  throw Exception('Missing OPENAI_API_KEY in .env');
}
```

**Security**: `.env` is in `.gitignore` - never commit API keys!

---

## Adding New Features

### Adding a New Screen

**1. Create screen file**:
```dart
// lib/presentation/screens/my_screen.dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyProvider>();
    return Scaffold(/* ... */);
  }
}
```

**2. Add route** (if using named routes):
```dart
// In MaterialApp
routes: {
  '/my-screen': (_) => MyScreen(),
}
```

**3. Navigate**:
```dart
Navigator.pushNamed(context, '/my-screen');
```

---

### Adding a New Provider

**1. Create provider**:
```dart
// lib/presentation/providers/my_provider.dart
class MyProvider extends ChangeNotifier {
  final MyUseCase _useCase;
  
  MyProvider(this._useCase);
  
  Future<void> doSomething() async {
    // ... business logic
    notifyListeners();
  }
}
```

**2. Register in DependencyInjection**:
```dart
// lib/core/utils/dependency_injection.dart
static late MyProvider _myProvider;

static Future<void> init() async {
  // ... existing init
  _myProvider = MyProvider(_myUseCase);
}

static MyProvider get myProvider => _myProvider;
```

**3. Add to MultiProvider**:
```dart
// In main.dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider.value(value: DependencyInjection.myProvider),
  ],
  child: MyApp(),
)
```

---

### Adding a New Service

**1. Create service**:
```dart
// lib/services/my_service.dart
class MyService {
  static Future<void> initialize() async {
    // Setup code
  }
  
  Future<void> doWork() async {
    // Service logic
  }
}
```

**2. Initialize in main()**:
```dart
void _initializeServices() {
  Future.delayed(const Duration(seconds: 3), () async {
    await MyService.initialize();
  });
}
```

---

## Common Patterns

### Pattern 1: Accessing Providers

**Read (one-time)**:
```dart
final provider = context.read<MyProvider>();
provider.doSomething();
```

**Watch (rebuild on change)**:
```dart
final provider = context.watch<MyProvider>();
return Text(provider.data);
```

**Select (rebuild on specific field change)**:
```dart
final data = context.select((MyProvider p) => p.data);
```

---

### Pattern 2: Error Handling

**Use case returns Result**:
```dart
final result = await useCase.execute();

if (result is Success<T>) {
  final data = result.data;
  // Handle success
} else if (result is ResultError<T>) {
  final error = result.failure;
  // Handle error
}
```

**Never throw exceptions in use cases/repositories** - use Result pattern.

---

### Pattern 3: Async Initialization

**Post-frame callback**:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<MyProvider>().loadData();
  });
}
```

Use when provider needs to be accessed after first frame.

---

## Testing

### Widget Tests
```dart
testWidgets('should display app', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockProvider()),
      ],
      child: MyApp(),
    ),
  );
  
  expect(find.text('Quran App'), findsOneWidget);
});
```

### Integration Tests
```dart
void main() {
  testWidgets('full app flow', (tester) async {
    await main(); // Run actual main()
    await tester.pumpAndSettle();
    
    // Test navigation, interactions, etc.
  });
}
```

---

## Build & Run

**Development**:
```bash
flutter run                    # Run on connected device
flutter run -d macos           # Run on macOS
flutter run --debug            # Debug mode (default)
```

**Release**:
```bash
flutter run --release          # Release build for testing
flutter build apk --release    # Android APK
flutter build ios --release    # iOS (requires Xcode)
```

**Dependencies**:
```bash
flutter pub get                # Install dependencies
flutter clean                  # Clean build cache
flutter pub upgrade            # Upgrade dependencies
```

**Code Generation** (for Hive):
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## Common Issues

### Issue 1: Hive Adapter Not Registered
**Error**: `Cannot read, unknown type`

**Solution**: Register adapter in main() before runApp():
```dart
Hive.registerAdapter(MyModelAdapter());
```

---

### Issue 2: Missing .env File
**Error**: `FileSystemException: Cannot open file, path = '.env'`

**Solution**: Create `.env` in project root:
```bash
echo "OPENAI_API_KEY=sk-..." > .env
```

---

### Issue 3: Provider Not Found
**Error**: `Could not find the correct Provider<T>`

**Solution**: Ensure provider is registered in MultiProvider in main.dart.

---

### Issue 4: Hot Reload Breaks State
**Issue**: Hot reload loses provider state

**Solution**: Use hot restart (⌘+Shift+\ on macOS) instead of hot reload for provider changes.

---

## File Naming Conventions

- **Screens**: `my_screen.dart` (lowercase with underscores)
- **Widgets**: `my_widget.dart`
- **Providers**: `my_provider.dart`
- **Services**: `my_service.dart`
- **Models**: `my_model.dart` (+ `my_model.g.dart` if Hive)
- **Use Cases**: `my_usecase.dart`
- **Entities**: `my_entity.dart`

---

## Project Statistics

- **Total Lines**: ~15,000+ LOC
- **Screens**: 17 screens
- **Providers**: 9 providers
- **Services**: 11 services
- **Entities**: 4 core entities
- **Use Cases**: 2+ use cases
- **Hive Models**: 6 cached models
- **Supported Languages**: 5 (en, ar, ur, fr, id)
- **API Integrations**: 3 (Quran API, Prayer Times API, OpenAI API)

---

## Related Documentation

- **Root Project**: `/AGENTS.md` - Architecture overview, workflows, patterns
- **Core Layer**: `lib/core/AGENTS.md` - Utilities, DI, theme, errors
- **Domain Layer**: `lib/domain/AGENTS.md` - Business logic, entities, use cases
- **Data Layer**: `lib/data/AGENTS.md` - Repositories, caching, API clients
- **Presentation Layer**: `lib/presentation/AGENTS.md` - UI, providers, screens
- **Services Layer**: `lib/services/AGENTS.md` - External integrations

---

**Last Updated**: November 2025
**Flutter Version**: >=3.0.0
**Dart Version**: >=3.0.0
