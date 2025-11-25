import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/quran_remote_datasource.dart';
import '../../data/repositories/quran_repository.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/get_surah_usecase.dart';
import '../../domain/usecases/manage_bookmarks_usecase.dart';
import '../../domain/usecases/get_surah_translations_usecase.dart';
import '../../domain/usecases/get_verse_translation_usecase.dart';
import '../../domain/usecases/get_available_translations_usecase.dart';
import '../../domain/usecases/get_verse_tafsir_usecase.dart';
import '../../domain/usecases/get_available_tafsirs_usecase.dart';
import '../../presentation/providers/bookmarks_provider.dart';
import '../../presentation/providers/surah_provider.dart';
import '../../presentation/providers/translation_provider.dart';
import '../../presentation/providers/tafsir_provider.dart';

/// Simple dependency injection container for clean architecture
/// In a larger app, consider using GetIt, Riverpod, or Injectable
class DependencyInjection {
  // Initialization tracking flag
  static bool _isInitialized = false;

  // External resources
  static http.Client? _httpClient;

  // Core dependencies
  static late QuranRepositoryInterface _quranRepository;
  static late GetSurahUseCase _getSurahUseCase;
  static late ManageBookmarksUseCase _manageBookmarksUseCase;
  static late GetSurahTranslationsUseCase _getSurahTranslationsUseCase;
  static late GetVerseTranslationUseCase _getVerseTranslationUseCase;
  static late GetAvailableTranslationsUseCase _getAvailableTranslationsUseCase;
  static late GetVerseTafsirUseCase _getVerseTafsirUseCase;
  static late GetAvailableTafsirsUseCase _getAvailableTafsirsUseCase;
  static late BookmarksProvider _bookmarksProvider;
  static late SurahProvider _surahProvider;
  static late TranslationProvider _translationProvider;
  static late TafsirProvider _tafsirProvider;

  /// Initialize all dependencies
  static Future<void> init() async {
    // External dependencies
    _httpClient = http.Client();
    final connectivity = Connectivity();

    // Data sources
    final remoteDataSource = QuranRemoteDataSource(client: _httpClient!);

    // Repository
    final repository = QuranRepository(
      remoteDataSource: remoteDataSource,
      connectivity: connectivity,
    );
    await repository.initialize();
    _quranRepository = repository;

    // Use cases
    _getSurahUseCase = GetSurahUseCase(_quranRepository);
    _manageBookmarksUseCase = ManageBookmarksUseCase(_quranRepository);
    _getSurahTranslationsUseCase =
        GetSurahTranslationsUseCase(_quranRepository);
    _getVerseTranslationUseCase = GetVerseTranslationUseCase(_quranRepository);
    _getAvailableTranslationsUseCase =
        GetAvailableTranslationsUseCase(_quranRepository);
    _getVerseTafsirUseCase = GetVerseTafsirUseCase(_quranRepository);
    _getAvailableTafsirsUseCase = GetAvailableTafsirsUseCase(_quranRepository);

    // Providers
    _bookmarksProvider = BookmarksProvider(_manageBookmarksUseCase);
    _surahProvider = SurahProvider(_getSurahUseCase);
    _translationProvider = TranslationProvider(
      getSurahTranslationsUseCase: _getSurahTranslationsUseCase,
      getVerseTranslationUseCase: _getVerseTranslationUseCase,
      getAvailableTranslationsUseCase: _getAvailableTranslationsUseCase,
    );
    _tafsirProvider = TafsirProvider(
      getVerseTafsirUseCase: _getVerseTafsirUseCase,
      getAvailableTafsirsUseCase: _getAvailableTafsirsUseCase,
    );

    // Mark as initialized
    _isInitialized = true;
  }

  /// Get the Quran repository instance
  static QuranRepositoryInterface get quranRepository {
    _ensureInitialized();
    return _quranRepository;
  }

  /// Get the GetSurahUseCase instance
  static GetSurahUseCase get getSurahUseCase {
    _ensureInitialized();
    return _getSurahUseCase;
  }

  /// Get the ManageBookmarksUseCase instance
  static ManageBookmarksUseCase get manageBookmarksUseCase {
    _ensureInitialized();
    return _manageBookmarksUseCase;
  }

  /// Get the BookmarksProvider instance
  static BookmarksProvider get bookmarksProvider {
    _ensureInitialized();
    return _bookmarksProvider;
  }

  /// Get the SurahProvider instance
  static SurahProvider get surahProvider {
    _ensureInitialized();
    return _surahProvider;
  }

  /// Get the TranslationProvider instance
  static TranslationProvider get translationProvider {
    _ensureInitialized();
    return _translationProvider;
  }

  /// Get the TafsirProvider instance
  static TafsirProvider get tafsirProvider {
    _ensureInitialized();
    return _tafsirProvider;
  }

  /// Factory method to create new providers when needed
  static BookmarksProvider createBookmarksProvider() {
    _ensureInitialized();
    return BookmarksProvider(_manageBookmarksUseCase);
  }

  /// Factory method to create new surah providers when needed
  static SurahProvider createSurahProvider() {
    _ensureInitialized();
    return SurahProvider(_getSurahUseCase);
  }

  /// Factory method to create new translation providers when needed
  static TranslationProvider createTranslationProvider() {
    _ensureInitialized();
    return TranslationProvider(
      getSurahTranslationsUseCase: _getSurahTranslationsUseCase,
      getVerseTranslationUseCase: _getVerseTranslationUseCase,
      getAvailableTranslationsUseCase: _getAvailableTranslationsUseCase,
    );
  }

  /// Factory method to create new tafsir providers when needed
  static TafsirProvider createTafsirProvider() {
    _ensureInitialized();
    return TafsirProvider(
      getVerseTafsirUseCase: _getVerseTafsirUseCase,
      getAvailableTafsirsUseCase: _getAvailableTafsirsUseCase,
    );
  }

  /// Dispose resources when app closes
  static Future<void> dispose() async {
    try {
      // Dispose repository resources (Hive boxes)
      if (_isInitialized) {
        await _quranRepository.dispose();
      }
    } catch (e) {
      // Log error but continue cleanup
    } finally {
      // Common cleanup code that must run regardless of errors
      if (_httpClient != null) {
        _httpClient!.close();
        _httpClient = null;
      }
      _isInitialized = false;
    }
  }

  /// Private method to ensure dependencies are initialized before access
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'DependencyInjection has not been initialized. Call DependencyInjection.init() first.',
      );
    }
  }
}
