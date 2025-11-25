import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/usecases/get_surah_translations_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock repository for testing
class MockQuranRepository implements QuranRepositoryInterface {
  bool shouldSucceed = true;
  List<String>? mockTranslations;
  Failure? mockFailure;

  @override
  Future<Result<List<String>>> getSurahTranslations(
      int surahNumber, String translationKey) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslations ?? ['Translation 1', 'Translation 2']);
  }

  // Other required methods (not used in these tests)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetSurahTranslationsUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetSurahTranslationsUseCase(mockRepository);
  });

  group('GetSurahTranslationsUseCase', () {
    test('should return success when surah number is valid', () async {
      // Arrange
      const validSurahNumber = 1; // Al-Fatiha
      const translationKey = 'en.sahih';
      mockRepository.shouldSucceed = true;
      mockRepository.mockTranslations = [
        'Translation verse 1',
        'Translation verse 2'
      ];

      // Act
      final result = await useCase.execute(
        surahNumber: validSurahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<Success<List<String>>>());
      final successResult = result as Success<List<String>>;
      expect(successResult.data,
          equals(['Translation verse 1', 'Translation verse 2']));
    });

    test('should return InvalidInputFailure when surah number is less than 1',
        () async {
      // Arrange
      const invalidSurahNumber = 0;
      const translationKey = 'en.sahih';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<List<String>>>());
      final errorResult = result as ResultError<List<String>>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(
          errorResult.failure.message, contains('Must be between 1 and 114'));
    });

    test(
        'should return InvalidInputFailure when surah number is greater than 114',
        () async {
      // Arrange
      const invalidSurahNumber = 115;
      const translationKey = 'en.sahih';

      // Act
      final result = await useCase.execute(
        surahNumber: invalidSurahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<List<String>>>());
      final errorResult = result as ResultError<List<String>>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(
          errorResult.failure.message, contains('Must be between 1 and 114'));
    });

    test('should return InvalidInputFailure when translation key is empty',
        () async {
      // Arrange
      const validSurahNumber = 2;
      const emptyTranslationKey = '';

      // Act
      final result = await useCase.execute(
        surahNumber: validSurahNumber,
        translationKey: emptyTranslationKey,
      );

      // Assert
      expect(result, isA<ResultError<List<String>>>());
      final errorResult = result as ResultError<List<String>>;
      expect(errorResult.failure, isA<InvalidInputFailure>());
      expect(errorResult.failure.message,
          contains('Translation key cannot be empty'));
    });

    test('should return NetworkFailure when repository fails', () async {
      // Arrange
      const validSurahNumber = 1;
      const translationKey = 'en.sahih';
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure =
          NetworkFailure(message: 'No internet connection');

      // Act
      final result = await useCase.execute(
        surahNumber: validSurahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<ResultError<List<String>>>());
      final errorResult = result as ResultError<List<String>>;
      expect(errorResult.failure, isA<NetworkFailure>());
      expect(errorResult.failure.message, contains('No internet connection'));
    });

    test('should handle boundary values correctly (surah 1)', () async {
      // Arrange
      const surahNumber = 1;
      const translationKey = 'en.sahih';
      mockRepository.mockTranslations = ['Translation 1'];

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<Success<List<String>>>());
    });

    test('should handle boundary values correctly (surah 114)', () async {
      // Arrange
      const surahNumber = 114;
      const translationKey = 'en.sahih';
      mockRepository.mockTranslations = [
        'Translation 1',
        'Translation 2',
        'Translation 3'
      ];

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<Success<List<String>>>());
      final successResult = result as Success<List<String>>;
      expect(successResult.data.length, equals(3));
    });

    test('should handle different translation keys correctly', () async {
      // Arrange
      const surahNumber = 1;
      final translationKeys = [
        'en.sahih',
        'en.yusufali',
        'ar.muyassar',
        'ur.jalandhry'
      ];

      for (final key in translationKeys) {
        // Act
        final result = await useCase.execute(
          surahNumber: surahNumber,
          translationKey: key,
        );

        // Assert
        expect(result, isA<Success<List<String>>>(),
            reason: 'Failed for key: $key');
      }
    });

    test('should return empty list from repository correctly', () async {
      // Arrange
      const surahNumber = 1;
      const translationKey = 'en.sahih';
      mockRepository.mockTranslations = [];

      // Act
      final result = await useCase.execute(
        surahNumber: surahNumber,
        translationKey: translationKey,
      );

      // Assert
      expect(result, isA<Success<List<String>>>());
      final successResult = result as Success<List<String>>;
      expect(successResult.data, isEmpty);
    });
  });
}
