import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/usecases/get_verse_tafsir_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock repository for testing
class MockQuranRepository implements QuranRepositoryInterface {
  bool shouldSucceed = true;
  String? mockTafsir;
  Failure? mockFailure;

  @override
  Future<Result<String>> getVerseTafsir(
      int surahNumber, int verseNumber, String tafsirKey) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTafsir ?? 'Tafsir explanation text');
  }

  // Other required methods (not used in these tests)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetVerseTafsirUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetVerseTafsirUseCase(mockRepository);
  });

  group('GetVerseTafsirUseCase', () {
    test('should return success when surah and verse numbers are valid',
        () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const tafsirKey = 'en.muyassar';
      mockRepository.shouldSucceed = true;
      mockRepository.mockTafsir = 'Praise be to Allah, Lord of all the worlds.';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
      );

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.data, contains('Praise'));
    });

    test('should return InvalidInputFailure when surah number is less than 1',
        () async {
      // Arrange
      const invalidSurahNumber = 0;
      const verseNumber = 1;
      const tafsirKey = 'en.muyassar';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
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
      const tafsirKey = 'en.muyassar';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
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
      const tafsirKey = 'en.muyassar';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: invalidVerseNumber,
        tafsirKey: tafsirKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(errorResult.failure.message, contains('Must be greater than 0'));
    });

    test('should return InvalidInputFailure when tafsir key is empty',
        () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const emptyTafsirKey = '';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirKey: emptyTafsirKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(
          errorResult.failure.message, contains('Tafsir key cannot be empty'));
    });

    test('should return NetworkFailure when repository fails', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const tafsirKey = 'en.muyassar';
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure =
          NetworkFailure(message: 'No internet connection');

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<NetworkFailure>());
    });

    test('should handle CacheFailure correctly', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const tafsirKey = 'en.muyassar';
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = CacheFailure(message: 'Cache read failed');

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
      );

      // Assert
      expect(result, isA<ResultError<String>>());
      final errorResult = result as ResultError<String>;
      expect(errorResult.failure, isA<CacheFailure>());
    });

    test('should handle different tafsir keys', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      final tafsirKeys = ['en.muyassar', 'ar.muyassar'];

      for (final key in tafsirKeys) {
        // Act
        final result = await useCase.execute(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          tafsirKey: key,
        );

        // Assert
        expect(result, isA<Success<String>>(), reason: 'Failed for key: $key');
      }
    });

    test('should handle empty tafsir text from repository', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;
      const tafsirKey = 'en.muyassar';
      mockRepository.mockTafsir = '';

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirKey: tafsirKey,
      );

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.data, isEmpty);
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
          tafsirKey: 'en.muyassar',
        );

        // Assert
        expect(result, isA<Success<String>>(),
            reason:
                'Failed for surah ${testCase['surah']}, verse ${testCase['verse']}');
      }
    });
  });
}
