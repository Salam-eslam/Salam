import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/usecases/get_verse_translation_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock repository for testing
class MockQuranRepository implements QuranRepositoryInterface {
  bool shouldSucceed = true;
  String? mockTranslation;
  Failure? mockFailure;

  @override
  Future<Result<String>> getVerseTranslation(
      int surahNumber, int verseNumber, String translationKey) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslation ?? 'Verse translation text');
  }

  // Other required methods (not used in these tests)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetVerseTranslationUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetVerseTranslationUseCase(mockRepository);
  });

  group('GetVerseTranslationUseCase', () {
    test('should return success when surah and verse numbers are valid',
        () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const translationKey = 'en.sahih';
      mockRepository.shouldSucceed = true;
      mockRepository.mockTranslation =
          'In the name of Allah, the Entirely Merciful, the Especially Merciful.';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.data, contains('Allah'));
    });

    test('should return InvalidInputFailure when surah number is less than 1',
        () async {
      // Arrange
      const invalidSurahNumber = 0;
      const verseNumber = 1;
      const translationKey = 'en.sahih';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        verseNumber: verseNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(
          errorResult.failure.message, contains('Must be between 1 and 114'));
    });

    test(
        'should return InvalidInputFailure when surah number is greater than 114',
        () async {
      // Arrange
      const invalidSurahNumber = 115;
      const verseNumber = 1;
      const translationKey = 'en.sahih';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        verseNumber: verseNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
    });

    test('should return InvalidInputFailure when verse number is less than 1',
        () async {
      // Arrange
      const surahNumber = 1;
      const invalidVerseNumber = 0;
      const translationKey = 'en.sahih';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: invalidVerseNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(errorResult.failure.message, contains('Must be greater than 0'));
    });

    test('should return InvalidInputFailure when translation key is empty',
        () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const emptyTranslationKey = '';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        translationKey: emptyTranslationKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(errorResult.failure.message,
          contains('Translation key cannot be empty'));
    });

    test('should return NetworkFailure when repository fails', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const translationKey = 'en.sahih';
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure =
          NetworkFailure(message: 'No internet connection');

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<NetworkFailure>());
    });

    test('should handle boundary values for different surahs', () async {
      // Arrange
      final testCases = [
        {'surah': 1, 'verse': 7}, // Al-Fatiha last verse
        {'surah': 2, 'verse': 1}, // Al-Baqarah first verse
        {'surah': 114, 'verse': 6}, // An-Nas last verse
      ];

      for (final testCase in testCases) {
        // Act
        final result = await useCase.execute(
          surahNumber: testCase['surah'] as int,
          verseNumber: testCase['verse'] as int,
          translationKey: 'en.sahih',
        );

        // Assert
        expect(result, isA<Success<String>>(),
            reason:
                'Failed for surah ${testCase['surah']}, verse ${testCase['verse']}');
      }
    });

    test('should handle different translation keys', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      final translationKeys = ['en.sahih', 'en.yusufali', 'ar.muyassar'];

      for (final key in translationKeys) {
        // Act
        final result = await useCase.execute(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          translationKey: key,
        );

        // Assert
        expect(result, isA<Success<String>>(), reason: 'Failed for key: $key');
      }
    });
  });
}
