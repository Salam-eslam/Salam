import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/get_surah_translations_usecase.dart';
import '../../domain/usecases/get_verse_translation_usecase.dart';
import '../../domain/usecases/get_available_translations_usecase.dart';
import '../../core/utils/logger_service.dart';

/// Provider for managing translation state
///
/// Provides access to verse translations following clean architecture
/// Uses use cases to interact with the repository
class TranslationProvider with ChangeNotifier {
  final GetSurahTranslationsUseCase _getSurahTranslationsUseCase;
  final GetVerseTranslationUseCase _getVerseTranslationUseCase;
  final GetAvailableTranslationsUseCase _getAvailableTranslationsUseCase;

  // State
  List<String>? _surahTranslations;
  List<TranslationInfo>? _availableTranslations;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<String>? get surahTranslations => _surahTranslations;
  List<TranslationInfo>? get availableTranslations => _availableTranslations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTranslations =>
      _surahTranslations != null && _surahTranslations!.isNotEmpty;

  TranslationProvider({
    required GetSurahTranslationsUseCase getSurahTranslationsUseCase,
    required GetVerseTranslationUseCase getVerseTranslationUseCase,
    required GetAvailableTranslationsUseCase getAvailableTranslationsUseCase,
  })  : _getSurahTranslationsUseCase = getSurahTranslationsUseCase,
        _getVerseTranslationUseCase = getVerseTranslationUseCase,
        _getAvailableTranslationsUseCase = getAvailableTranslationsUseCase;

  /// Load translations for an entire surah
  ///
  /// [surahNumber] - The surah number (1-114)
  /// [translationKey] - The translation edition key
  ///
  /// Returns true if successful, false otherwise
  Future<bool> loadSurahTranslations(
    int surahNumber,
    String translationKey,
  ) async {
    _setLoading(true);

    final result = await _getSurahTranslationsUseCase.execute(
      surahNumber: surahNumber,
      translationKey: translationKey,
    );

    if (result is Success<List<String>>) {
      _surahTranslations = result.data;
      _error = null;
      _setLoading(false);
      logger.info(
          'Loaded ${result.data.length} translations for surah $surahNumber');
      return true;
    } else if (result is ResultError<List<String>>) {
      _error = result.failure.message;
      _setLoading(false);
      logger.error('Failed to load translations: ${result.failure.message}');
      return false;
    }

    _setLoading(false);
    return false;
  }

  /// Get translation for a specific verse
  ///
  /// If surah translations are already loaded, returns from cache
  /// Otherwise fetches just the single verse translation
  Future<String?> getVerseTranslation(
    int surahNumber,
    int verseNumber,
    String translationKey,
  ) async {
    // If we have the full surah loaded, return from cache
    if (_surahTranslations != null &&
        verseNumber <= _surahTranslations!.length) {
      return _surahTranslations![verseNumber - 1];
    }

    // Otherwise fetch just this verse
    final result = await _getVerseTranslationUseCase.execute(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      translationKey: translationKey,
    );

    if (result is Success<String>) {
      return result.data;
    } else if (result is ResultError<String>) {
      logger
          .error('Failed to get verse translation: ${result.failure.message}');
      return null;
    }

    return null;
  }

  /// Load list of available translations
  Future<void> loadAvailableTranslations() async {
    final result = await _getAvailableTranslationsUseCase.execute();

    if (result is Success<List<TranslationInfo>>) {
      _availableTranslations = result.data;
      logger.info('Loaded ${result.data.length} available translations');
      notifyListeners();
    } else if (result is ResultError<List<TranslationInfo>>) {
      logger.error(
          'Failed to load available translations: ${result.failure.message}');
    }
  }

  /// Clear translations (e.g., when navigating away)
  void clearTranslations() {
    _surahTranslations = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
