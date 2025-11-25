import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger_service.dart';
import 'data/models/cached_surah.dart';
import 'data/models/bookmark.dart';
import 'data/models/page_progress.dart';
import 'domain/repositories/quran_repository_interface.dart';
import 'presentation/providers/bookmarks_provider.dart';
import 'presentation/providers/surah_provider.dart';
import 'presentation/providers/translation_provider.dart';
import 'presentation/providers/tafsir_provider.dart';
import 'presentation/providers/preference_settings_provider.dart';
import 'presentation/providers/reading_progress_provider.dart';
import 'presentation/providers/enhanced_theme_provider.dart';
import 'presentation/providers/reading_stats_provider.dart';
import 'presentation/providers/chat_history_provider.dart';
import 'presentation/providers/quran_page_provider.dart';
import 'presentation/providers/page_progress_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'services/auto_cache_service.dart';
import 'services/prayer_notification_service.dart';
import 'services/accessibility_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Suppress Google Fonts AssetManifest errors (known hot reload issue)
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception;
      if (exception.toString().contains('AssetManifest.json') ||
          exception.toString().contains('google_fonts')) {
        // Silently ignore Google Fonts loading errors - fallback fonts will be used
        logger.debug(
            'Google Fonts loading error suppressed (using fallback fonts)');
        return;
      }
      // For all other errors, use default error handler
      FlutterError.presentError(details);
    };

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Register Hive adapters for cached models
    Hive.registerAdapter(CachedSurahAdapter());
    Hive.registerAdapter(CachedAyahAdapter());
    Hive.registerAdapter(BookmarkAdapter());
    Hive.registerAdapter(PageProgressAdapter());

    // Initialize GetIt dependency injection
    await setupDependencies();

    // Initialize auto-preloading of popular surahs in background
    _initializeCache();

    // Initialize prayer notification service
    _initializeServices();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PreferenceSettingsProvider()),
          ChangeNotifierProvider(create: (_) => getIt<BookmarksProvider>()),
          ChangeNotifierProvider(create: (_) => getIt<SurahProvider>()),
          ChangeNotifierProvider(create: (_) => getIt<TranslationProvider>()),
          ChangeNotifierProvider(create: (_) => getIt<TafsirProvider>()),
          ChangeNotifierProvider(create: (_) => ReadingProgressProvider()),
          ChangeNotifierProvider(create: (_) => getIt<ReadingStatsProvider>()),
          ChangeNotifierProvider(create: (_) => EnhancedThemeProvider()),
          ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
          ChangeNotifierProvider(
            create: (_) => QuranPageProvider(getIt<QuranRepositoryInterface>()),
          ),
          ChangeNotifierProvider(create: (_) => PageProgressProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // Catch async errors from google_fonts and suppress them
    if (error.toString().contains('AssetManifest.json') ||
        error.toString().contains('google_fonts')) {
      logger
          .debug('Google Fonts async error suppressed (using fallback fonts)');
      return;
    }
    // For other errors, log to console
    logger.error('Unhandled error: $error', error, stack);
  });
}

void _initializeCache() {
  // Cache common surahs in background for permanent offline access
  Future.delayed(const Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}

void _initializeServices() {
  // Initialize prayer notifications and daily ayah
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      await PrayerNotificationService.initialize();
      await PrayerNotificationService.scheduleDailyAyahNotification();

      // Initialize accessibility service
      await AccessibilityService().initialize();
    } catch (e) {
      // Failed to initialize services: $e
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Load theme settings and initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnhancedThemeProvider>().loadSettings();
      context.read<PageProgressProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quran App - القرآن الكريم',

          // Material 3 themes with enhanced customization
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localization support
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
            Locale('ur', ''), // Urdu
            Locale('fr', ''), // French
            Locale('id', ''), // Indonesian
          ],

          // Use system locale by default
          locale: const Locale('en', ''),

          home: const AppInitializer(),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

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
    final hasCompletedOnboarding =
        prefs.getBool('onboarding_completed') ?? false;

    await Future.delayed(const Duration(seconds: 1)); // Splash delay

    setState(() {
      _showOnboarding = !hasCompletedOnboarding;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/icon_quran.png'),
                width: 100,
                height: 100,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              SizedBox(height: 16),
              Text(
                'Quran App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _showOnboarding ? const OnboardingScreen() : const MainScreen();
  }
}
