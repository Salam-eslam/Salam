import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for getting all translations for a specific surah
///
/// Business Rules:
/// - Surah number must be between 1 and 114
/// - Translation key must not be empty
/// - Returns empty list if translations are not available
class GetSurahTranslationsUseCase {
  final QuranRepositoryInterface repository;

  const GetSurahTranslationsUseCase(this.repository);

  /// Execute the use case
  ///
  /// [surahNumber] - The surah number (1-114)
  /// [translationKey] - The translation edition key (e.g., 'en.sahih', 'ar.muyassar')
  ///
  /// Returns Result<List<String>> containing translations for each verse
  Future<Result<List<String>>> execute({
    required int surahNumber,
    required String translationKey,
  }) async {
    // Validate business rules
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(
        message:
            'Invalid surah number: $surahNumber. Must be between 1 and 114.',
      ));
    }

    if (translationKey.trim().isEmpty) {
      return ResultError(InvalidInputFailure(
        message: 'Translation key cannot be empty',
      ));
    }

    // Delegate to repository
    return await repository.getSurahTranslations(surahNumber, translationKey);
  }
}
