import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/get_verse_tafsir_usecase.dart';
import '../../domain/usecases/get_available_tafsirs_usecase.dart';
import '../../core/utils/logger_service.dart';

/// Provider for managing tafsir (commentary) state
///
/// Provides access to verse tafsir following clean architecture
/// Uses use cases to interact with the repository
class TafsirProvider with ChangeNotifier {
  final GetVerseTafsirUseCase _getVerseTafsirUseCase;
  final GetAvailableTafsirsUseCase _getAvailableTafsirsUseCase;

  // State - maps verse key (surahNumber_verseNumber) to tafsir text
  final Map<String, String> _tafsirCache = {};
  List<TafsirInfo>? _availableTafsirs;
  bool _isLoading = false;
  String? _error;
  String? _currentTafsirKey;

  // Getters
  Map<String, String> get tafsirCache => _tafsirCache;
  List<TafsirInfo>? get availableTafsirs => _availableTafsirs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentTafsirKey => _currentTafsirKey;

  TafsirProvider({
    required GetVerseTafsirUseCase getVerseTafsirUseCase,
    required GetAvailableTafsirsUseCase getAvailableTafsirsUseCase,
  })  : _getVerseTafsirUseCase = getVerseTafsirUseCase,
        _getAvailableTafsirsUseCase = getAvailableTafsirsUseCase;

  /// Load tafsir for a specific verse
  ///
  /// [surahNumber] - The surah number (1-114)
  /// [verseNumber] - The verse number within the surah
  /// [tafsirKey] - The tafsir edition key
  ///
  /// Returns the tafsir text if successful, null otherwise
  Future<String?> loadVerseTafsir(
    int surahNumber,
    int verseNumber,
    String tafsirKey,
  ) async {
    final cacheKey = '${surahNumber}_$verseNumber';

    // Return from cache if available and using same tafsir key
    if (_currentTafsirKey == tafsirKey && _tafsirCache.containsKey(cacheKey)) {
      return _tafsirCache[cacheKey];
    }

    _setLoading(true);
    _currentTafsirKey = tafsirKey;

    final result = await _getVerseTafsirUseCase.execute(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      tafsirKey: tafsirKey,
    );

    if (result is Success<String>) {
      _tafsirCache[cacheKey] = result.data;
      _error = null;
      _setLoading(false);
      logger.info('Loaded tafsir for surah $surahNumber, verse $verseNumber');
      return result.data;
    } else if (result is ResultError<String>) {
      _error = result.failure.message;
      _setLoading(false);
      logger.error('Failed to load tafsir: ${result.failure.message}');
      return null;
    }

    _setLoading(false);
    return null;
  }

  /// Get tafsir for a verse if it's already in cache
  String? getTafsir(int surahNumber, int verseNumber) {
    final cacheKey = '${surahNumber}_$verseNumber';
    return _tafsirCache[cacheKey];
  }

  /// Check if tafsir is available for a verse
  bool hasTafsir(int surahNumber, int verseNumber) {
    final cacheKey = '${surahNumber}_$verseNumber';
    return _tafsirCache.containsKey(cacheKey);
  }

  /// Load list of available tafsir sources
  Future<void> loadAvailableTafsirs() async {
    final result = await _getAvailableTafsirsUseCase.execute();

    if (result is Success<List<TafsirInfo>>) {
      _availableTafsirs = result.data;
      logger.info('Loaded ${result.data.length} available tafsir sources');
      notifyListeners();
    } else if (result is ResultError<List<TafsirInfo>>) {
      logger
          .error('Failed to load available tafsirs: ${result.failure.message}');
    }
  }

  /// Clear all tafsir cache (e.g., when changing tafsir source)
  void clearTafsirs() {
    _tafsirCache.clear();
    _error = null;
    _currentTafsirKey = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
