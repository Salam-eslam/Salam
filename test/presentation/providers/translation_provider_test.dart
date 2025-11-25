import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/presentation/providers/translation_provider.dart';
import 'package:salam/domain/usecases/get_surah_translations_usecase.dart';
import 'package:salam/domain/usecases/get_verse_translation_usecase.dart';
import 'package:salam/domain/usecases/get_available_translations_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock use cases for testing
class MockGetSurahTranslationsUseCase extends GetSurahTranslationsUseCase {
  bool shouldSucceed = true;
  List<String>? mockTranslations;
  Failure? mockFailure;

  MockGetSurahTranslationsUseCase(super.repository);

  @override
  Future<Result<List<String>>> execute({
    required int surahNumber,
    required String translationKey,
  }) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslations ?? ['Translation 1', 'Translation 2']);
  }
}

class MockGetVerseTranslationUseCase extends GetVerseTranslationUseCase {
  bool shouldSucceed = true;
  String? mockTranslation;
  Failure? mockFailure;

  MockGetVerseTranslationUseCase(super.repository);

  @override
  Future<Result<String>> execute({
    required int surahNumber,
    required int verseNumber,
    required String translationKey,
  }) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslation ?? 'Verse translation');
  }
}

class MockGetAvailableTranslationsUseCase
    extends GetAvailableTranslationsUseCase {
  bool shouldSucceed = true;
  List<TranslationInfo>? mockTranslations;
  Failure? mockFailure;

  MockGetAvailableTranslationsUseCase(super.repository);

  @override
  Future<Result<List<TranslationInfo>>> execute() async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslations ?? const []);
  }
}

// Minimal mock repository (not used directly in provider tests)
class MockQuranRepository implements QuranRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TranslationProvider provider;
  late MockGetSurahTranslationsUseCase mockGetSurahTranslations;
  late MockGetVerseTranslationUseCase mockGetVerseTranslation;
  late MockGetAvailableTranslationsUseCase mockGetAvailableTranslations;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    mockGetSurahTranslations = MockGetSurahTranslationsUseCase(mockRepository);
    mockGetVerseTranslation = MockGetVerseTranslationUseCase(mockRepository);
    mockGetAvailableTranslations =
        MockGetAvailableTranslationsUseCase(mockRepository);

    provider = TranslationProvider(
      getSurahTranslationsUseCase: mockGetSurahTranslations,
      getVerseTranslationUseCase: mockGetVerseTranslation,
      getAvailableTranslationsUseCase: mockGetAvailableTranslations,
    );
  });

  group('TranslationProvider', () {
    group('Initial State', () {
      test('should have correct initial state', () {
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.surahTranslations, isNull);
        expect(provider.availableTranslations, isNull);
      });
    });

    group('loadSurahTranslations', () {
      test('should set loading state to true during execution', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = true;
        bool wasLoading = false;

        provider.addListener(() {
          if (provider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(wasLoading, isTrue);
      });

      test('should load translations successfully and update state', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = true;
        mockGetSurahTranslations.mockTranslations = [
          'Translation verse 1',
          'Translation verse 2',
          'Translation verse 3'
        ];

        // Act
        final result = await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(result, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.surahTranslations, isNotNull);
        expect(provider.surahTranslations!.length, equals(3));
        expect(provider.surahTranslations![0], equals('Translation verse 1'));
      });

      test('should handle failure and set error state', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = false;
        mockGetSurahTranslations.mockFailure =
            NetworkFailure(message: 'No internet connection');

        // Act
        final result = await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(result, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('No internet connection'));
        expect(provider.surahTranslations, isNull);
      });

      test('should notify listeners when state changes', () async {
        // Arrange
        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        mockGetSurahTranslations.shouldSucceed = true;

        // Act
        await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert - should notify at least twice (loading start, loading end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('should clear previous error on new successful load', () async {
        // Arrange - First load fails
        mockGetSurahTranslations.shouldSucceed = false;
        await provider.loadSurahTranslations(1, 'en.sahih');
        expect(provider.error, isNotNull);

        // Act - Second load succeeds
        mockGetSurahTranslations.shouldSucceed = true;
        await provider.loadSurahTranslations(2, 'en.sahih');

        // Assert
        expect(provider.error, isNull);
        expect(provider.surahTranslations, isNotNull);
      });

      test('should handle empty translations list', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = true;
        mockGetSurahTranslations.mockTranslations = [];

        // Act
        final result = await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(result, isTrue);
        expect(provider.surahTranslations, isEmpty);
      });
    });

    group('getVerseTranslation', () {
      test('should return verse translation successfully', () async {
        // Arrange
        mockGetVerseTranslation.shouldSucceed = true;
        mockGetVerseTranslation.mockTranslation =
            'In the name of Allah, the Entirely Merciful';

        // Act
        final result = await provider.getVerseTranslation(1, 1, 'en.sahih');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('Allah'));
      });

      test('should return null on failure but not set error', () async {
        // Arrange
        mockGetVerseTranslation.shouldSucceed = false;
        mockGetVerseTranslation.mockFailure =
            NetworkFailure(message: 'Network error');

        // Act
        final result = await provider.getVerseTranslation(1, 1, 'en.sahih');

        // Assert - getVerseTranslation just logs error, doesn't set provider.error
        expect(result, isNull);
      });

      test('should not update loading state during execution', () async {
        // Arrange
        mockGetVerseTranslation.shouldSucceed = true;
        bool wasLoading = false;

        provider.addListener(() {
          if (provider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await provider.getVerseTranslation(1, 1, 'en.sahih');

        // Assert - getVerseTranslation doesn't update loading state
        expect(wasLoading, isFalse);
        expect(provider.isLoading, isFalse);
      });
    });

    group('loadAvailableTranslations', () {
      test('should load available translations successfully', () async {
        // Arrange
        mockGetAvailableTranslations.shouldSucceed = true;
        mockGetAvailableTranslations.mockTranslations = const [
          TranslationInfo(
              key: 'en.sahih',
              name: 'Sahih International',
              author: 'Sahih International',
              language: 'English',
              languageCode: 'en'),
          TranslationInfo(
              key: 'ar.muyassar',
              name: 'Al-Muyassar',
              author: 'King Fahad Quran Complex',
              language: 'Arabic',
              languageCode: 'ar'),
        ];

        // Act
        await provider.loadAvailableTranslations();

        // Assert
        expect(provider.availableTranslations, isNotNull);
        expect(provider.availableTranslations!.length, equals(2));
        expect(provider.availableTranslations![0].key, equals('en.sahih'));
      });

      test('should handle failure when loading available translations',
          () async {
        // Arrange
        mockGetAvailableTranslations.shouldSucceed = false;

        // Act
        await provider.loadAvailableTranslations();

        // Assert - loadAvailableTranslations doesn't set error, it just logs
        // The provider won't have an error, but availableTranslations will be null
        expect(provider.availableTranslations, isNull);
      });
    });

    group('clearTranslations', () {
      test('should clear all translations and reset state', () async {
        // Arrange - Load some translations first
        mockGetSurahTranslations.shouldSucceed = true;
        await provider.loadSurahTranslations(1, 'en.sahih');
        expect(provider.surahTranslations, isNotNull);

        // Act
        provider.clearTranslations();

        // Assert
        expect(provider.surahTranslations, isNull);
        expect(provider.error, isNull);
      });

      test('should notify listeners when clearing', () {
        // Arrange
        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Act
        provider.clearTranslations();

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('Error Handling', () {
      test('should handle InvalidInputFailure', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = false;
        mockGetSurahTranslations.mockFailure =
            InvalidInputFailure(message: 'Invalid surah number');

        // Act
        await provider.loadSurahTranslations(999, 'en.sahih');

        // Assert
        expect(provider.error, contains('Invalid surah number'));
      });

      test('should handle CacheFailure', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = false;
        mockGetSurahTranslations.mockFailure =
            CacheFailure(message: 'Cache read failed');

        // Act
        await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(provider.error, contains('Cache read failed'));
      });

      test('should handle ServerFailure', () async {
        // Arrange
        mockGetSurahTranslations.shouldSucceed = false;
        mockGetSurahTranslations.mockFailure =
            ServerFailure(message: 'Server error 500');

        // Act
        await provider.loadSurahTranslations(1, 'en.sahih');

        // Assert
        expect(provider.error, contains('Server error 500'));
      });
    });
  });
}
