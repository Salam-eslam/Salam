import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/core/errors/failures.dart';
import 'package:salam/domain/entities/surah_entity.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/domain/usecases/get_surah_usecase.dart';

// Manual mock for testing (avoids Mockito sealed class issue)
class MockQuranRepository implements QuranRepositoryInterface {
  Result<Surah>? _mockGetSurahResult;
  Result<List<Surah>>? _mockGetAllSurahsResult;

  int? lastCalledSurahNumber;
  int getSurahCallCount = 0;

  void setupGetSurah(Result<Surah> result) {
    _mockGetSurahResult = result;
  }

  void setupGetAllSurahs(Result<List<Surah>> result) {
    _mockGetAllSurahsResult = result;
  }

  @override
  Future<Result<Surah>> getSurah(int surahNumber) async {
    getSurahCallCount++;
    lastCalledSurahNumber = surahNumber;
    return _mockGetSurahResult!;
  }

  @override
  Future<Result<List<Surah>>> getAllSurahs() async {
    return _mockGetAllSurahsResult!;
  }

  // Stub implementations for interface methods
  @override
  Future<Result<void>> addBookmark(
          int surahNumber, int verseNumber, String? note) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> cacheSurah(int surahNumber,
          {String? translationKey, String? reciterKey}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> clearCache() => throw UnimplementedError();

  @override
  Future<Result<bool>> isSurahCached(int surahNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<List<int>>> getCachedSurahs() => throw UnimplementedError();

  @override
  Future<Result<int>> getCacheSize() => throw UnimplementedError();

  @override
  Future<Result<void>> removeCachedSurah(int surahNumber) =>
      throw UnimplementedError();

  @override
  Future<void> dispose() async {}

  @override
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs() =>
      throw UnimplementedError();

  @override
  Future<Result<List<TranslationInfo>>> getAvailableTranslations() =>
      throw UnimplementedError();

  @override
  Future<Result<List<BookmarkedVerse>>> getBookmarkedVerses() =>
      throw UnimplementedError();

  @override
  Future<Result<ReadingProgress>> getReadingProgress() =>
      throw UnimplementedError();

  @override
  Future<Result<ReadingStatistics>> getReadingStatistics() =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getSurahAudioUrl(int surahNumber, String reciterKey) =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> getSurahTranslations(
          int surahNumber, String translationKey) =>
      throw UnimplementedError();

  @override
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseAudioUrl(
          int surahNumber, int verseNumber, String reciterKey) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> getVerses(int surahNumber,
          {int? startVerse, int? endVerse}) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseTafsir(
          int surahNumber, int verseNumber, String tafsirKey) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseTranslation(
          int surahNumber, int verseNumber, String translationKey) =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> isVerseBookmarked(int surahNumber, int verseNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markVerseAsRead(int surahNumber, int verseNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> removeBookmark(int surahNumber, int verseNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> searchArabicText(String query) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> searchTranslation(
          String query, String translationKey) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> updateLastRead(int surahNumber, int verseNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<List<ReciterInfo>>> getAvailableReciters() =>
      throw UnimplementedError();
}

void main() {
  late GetSurahUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetSurahUseCase(mockRepository);
  });

  group('GetSurahUseCase - execute()', () {
    final testSurah = Surah(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Fatihah',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
      verses: List.generate(
        7,
        (index) => Verse(
          number: index + 1,
          arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        ),
      ),
    );

    test('should return Surah from repository when surah number is valid',
        () async {
      // Arrange
      mockRepository.setupGetSurah(Success(testSurah));

      // Act
      final result = await useCase.execute(1);

      // Assert
      expect(result, isA<Success<Surah>>());
      expect((result as Success<Surah>).data, equals(testSurah));
      expect(mockRepository.getSurahCallCount, equals(1));
      expect(mockRepository.lastCalledSurahNumber, equals(1));
    });

    test('should return InvalidInputFailure when surah number is less than 1',
        () async {
      // Act
      final result = await useCase.execute(0);

      // Assert
      expect(result, isA<ResultError<Surah>>());
      final error = result as ResultError<Surah>;
      expect(error.failure, isA<InvalidInputFailure>());
      expect(error.failure.message, contains('Invalid surah number'));
      expect(mockRepository.getSurahCallCount, equals(0));
    });

    test(
        'should return InvalidInputFailure when surah number is greater than 114',
        () async {
      // Act
      final result = await useCase.execute(115);

      // Assert
      expect(result, isA<ResultError<Surah>>());
      final error = result as ResultError<Surah>;
      expect(error.failure, isA<InvalidInputFailure>());
      expect(error.failure.message, contains('Invalid surah number'));
      expect(mockRepository.getSurahCallCount, equals(0));
    });

    test('should return QuranDataFailure when surah has no verses', () async {
      // Arrange
      final emptySurah = Surah(
        number: 1,
        name: 'الفاتحة',
        englishName: 'Al-Fatihah',
        englishNameTranslation: 'The Opening',
        numberOfAyahs: 7,
        revelationType: 'Meccan',
        verses: [], // Empty verses list
      );
      mockRepository.setupGetSurah(Success(emptySurah));

      // Act
      final result = await useCase.execute(1);

      // Assert
      expect(result, isA<ResultError<Surah>>());
      final error = result as ResultError<Surah>;
      expect(error.failure, isA<QuranDataFailure>());
      expect(error.failure.message, contains('has no verses'));
    });

    test('should return QuranDataFailure when verse count mismatch', () async {
      // Arrange
      final invalidSurah = Surah(
        number: 1,
        name: 'الفاتحة',
        englishName: 'Al-Fatihah',
        englishNameTranslation: 'The Opening',
        numberOfAyahs: 7,
        revelationType: 'Meccan',
        verses: List.generate(
            5, (index) => const Verse(number: 1, arabicText: 'Test')),
      );
      mockRepository.setupGetSurah(Success(invalidSurah));

      // Act
      final result = await useCase.execute(1);

      // Assert
      expect(result, isA<ResultError<Surah>>());
      final error = result as ResultError<Surah>;
      expect(error.failure, isA<QuranDataFailure>());
      expect(error.failure.message, contains('Verse count mismatch'));
    });

    test('should propagate repository failures', () async {
      // Arrange
      const failure = NetworkFailure(message: 'No internet connection');
      mockRepository.setupGetSurah(const ResultError(failure));

      // Act
      final result = await useCase.execute(1);

      // Assert
      expect(result, isA<ResultError<Surah>>());
      expect((result as ResultError<Surah>).failure, equals(failure));
    });
  });

  group('GetSurahUseCase - executeAll()', () {
    test('should return all 114 surahs from repository', () async {
      // Arrange
      final allSurahs = List.generate(
        114,
        (index) => Surah(
          number: index + 1,
          name: 'Test ${index + 1}',
          englishName: 'Test ${index + 1}',
          englishNameTranslation: 'Test',
          numberOfAyahs: 5,
          revelationType: 'Meccan',
          verses:
              List.generate(5, (i) => Verse(number: i + 1, arabicText: 'Test')),
        ),
      );
      mockRepository.setupGetAllSurahs(Success(allSurahs));

      // Act
      final result = await useCase.executeAll();

      // Assert
      expect(result, isA<Success<List<Surah>>>());
      final surahs = (result as Success<List<Surah>>).data;
      expect(surahs.length, equals(114));
    });

    test('should propagate repository failures', () async {
      // Arrange
      const failure = NetworkFailure(message: 'No internet');
      mockRepository.setupGetAllSurahs(const ResultError(failure));

      // Act
      final result = await useCase.executeAll();

      // Assert
      expect(result, isA<ResultError<List<Surah>>>());
      expect((result as ResultError<List<Surah>>).failure, equals(failure));
    });
  });
}
