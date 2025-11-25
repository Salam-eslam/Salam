import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for getting tafsir (commentary) of a specific verse
///
/// Business Rules:
/// - Surah number must be between 1 and 114
/// - Verse number must be valid for the surah
/// - Tafsir key must not be empty
class GetVerseTafsirUseCase {
  final QuranRepositoryInterface repository;

  const GetVerseTafsirUseCase(this.repository);

  /// Execute the use case
  ///
  /// [surahNumber] - The surah number (1-114)
  /// [verseNumber] - The verse number within the surah
  /// [tafsirKey] - The tafsir edition key (e.g., 'en.muyassar', 'ar.muyassar')
  ///
  /// Returns Result<String> containing the verse tafsir
  Future<Result<String>> execute({
    required int surahNumber,
    required int verseNumber,
    required String tafsirKey,
  }) async {
    // Validate business rules
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(
        message:
            'Invalid surah number: $surahNumber. Must be between 1 and 114.',
      ));
    }

    if (verseNumber < 1) {
      return ResultError(InvalidInputFailure(
        message: 'Invalid verse number: $verseNumber. Must be greater than 0.',
      ));
    }

    if (tafsirKey.trim().isEmpty) {
      return ResultError(InvalidInputFailure(
        message: 'Tafsir key cannot be empty',
      ));
    }

    // Delegate to repository
    return await repository.getVerseTafsir(
      surahNumber,
      verseNumber,
      tafsirKey,
    );
  }
}
