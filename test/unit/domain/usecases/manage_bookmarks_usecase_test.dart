import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/core/errors/failures.dart';
import 'package:salam/domain/entities/surah_entity.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/domain/usecases/manage_bookmarks_usecase.dart';

/// Manual mock for QuranRepositoryInterface
/// Avoids Mockito sealed class issues
class MockQuranRepository implements QuranRepositoryInterface {
  // Control behavior
  bool shouldReturnError = false;
  Failure? failureToReturn;
  bool isBookmarked = false;
  List<BookmarkedVerse> bookmarksList = [];

  // Track calls
  int addBookmarkCallCount = 0;
  int removeBookmarkCallCount = 0;
  int isVerseBookmarkedCallCount = 0;

  @override
  Future<Result<bool>> isVerseBookmarked(
      int surahNumber, int verseNumber) async {
    isVerseBookmarkedCallCount++;

    if (shouldReturnError && failureToReturn != null) {
      return ResultError(failureToReturn!);
    }

    return Success(isBookmarked);
  }

  @override
  Future<Result<void>> addBookmark(
      int surahNumber, int verseNumber, String? note) async {
    addBookmarkCallCount++;

    if (shouldReturnError && failureToReturn != null) {
      return ResultError(failureToReturn!);
    }

    // Add to bookmarks list
    final bookmark = BookmarkedVerse(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      surahName: 'Test Surah',
      arabicText: 'Test Arabic',
      note: note,
      createdAt: DateTime.now(),
    );
    bookmarksList.add(bookmark);
    isBookmarked = true;

    return Success(null);
  }

  @override
  Future<Result<void>> removeBookmark(int surahNumber, int verseNumber) async {
    removeBookmarkCallCount++;

    if (shouldReturnError && failureToReturn != null) {
      return ResultError(failureToReturn!);
    }

    // Remove from bookmarks list
    bookmarksList.removeWhere(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
    isBookmarked = false;

    return Success(null);
  }

  @override
  Future<Result<List<BookmarkedVerse>>> getBookmarkedVerses() async {
    if (shouldReturnError && failureToReturn != null) {
      return ResultError(failureToReturn!);
    }

    return Success(bookmarksList);
  }

  // Stub all other interface methods - not needed for bookmark tests
  @override
  Future<Result<List<Surah>>> getAllSurahs() async =>
      throw UnimplementedError();

  @override
  Future<Result<Surah>> getSurah(int surahNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> getVerses(int surahNumber,
          {int? startVerse, int? endVerse}) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> searchArabicText(String query) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Verse>>> searchTranslation(
          String query, String translationKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<TranslationInfo>>> getAvailableTranslations() async =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseTranslation(
          int surahNumber, int verseNumber, String translationKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> getSurahTranslations(
          int surahNumber, String translationKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs() async =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseTafsir(
          int surahNumber, int verseNumber, String tafsirKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<ReciterInfo>>> getAvailableReciters() async =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getVerseAudioUrl(
          int surahNumber, int verseNumber, String reciterKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<String>> getSurahAudioUrl(
          int surahNumber, String reciterKey) async =>
      throw UnimplementedError();

  @override
  Future<Result<ReadingProgress>> getReadingProgress() async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> updateLastRead(int surahNumber, int verseNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markVerseAsRead(
          int surahNumber, int verseNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<ReadingStatistics>> getReadingStatistics() async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> cacheSurah(int surahNumber,
          {String? translationKey, String? reciterKey}) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> removeCachedSurah(int surahNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> isSurahCached(int surahNumber) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<int>>> getCachedSurahs() async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> clearCache() async => throw UnimplementedError();

  @override
  Future<Result<int>> getCacheSize() async => throw UnimplementedError();

  @override
  Future<void> dispose() async {}
}

void main() {
  late ManageBookmarksUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = ManageBookmarksUseCase(mockRepository);
  });

  group('ManageBookmarksUseCase - addBookmark', () {
    test('should add bookmark successfully with valid inputs', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 1;
      const verseNumber = 1;
      const note = 'Test note';

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: note,
      );

      // Assert
      expect(result, isA<Success<void>>());
      expect(mockRepository.isVerseBookmarkedCallCount, 1);
      expect(mockRepository.addBookmarkCallCount, 1);
      expect(mockRepository.bookmarksList.length, 1);
      expect(mockRepository.bookmarksList.first.note, note);
    });

    test('should add bookmark successfully without note', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 2;
      const verseNumber = 255; // Ayat Al-Kursi

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<Success<void>>());
      expect(mockRepository.addBookmarkCallCount, 1);
      expect(mockRepository.bookmarksList.first.note, isNull);
    });

    test('should return ValidationFailure when verse is already bookmarked',
        () async {
      // Arrange
      mockRepository.isBookmarked = true; // Already bookmarked
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<ValidationFailure>());
      expect(
        error.failure.message,
        contains('already bookmarked'),
      );
      expect(mockRepository.addBookmarkCallCount, 0); // Should not call add
    });

    test('should return InvalidInputFailure for surah number < 1', () async {
      // Arrange
      const surahNumber = 0;
      const verseNumber = 1;

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<InvalidInputFailure>());
      expect(error.failure.message, contains('Invalid surah number'));
    });

    test('should return InvalidInputFailure for surah number > 114', () async {
      // Arrange
      const surahNumber = 115;
      const verseNumber = 1;

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<InvalidInputFailure>());
      expect(error.failure.message, contains('Invalid surah number'));
    });

    test('should return InvalidInputFailure for verse number < 1', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 0;

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<InvalidInputFailure>());
      expect(error.failure.message, contains('Invalid verse number'));
    });

    test('should propagate repository failures', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      mockRepository.shouldReturnError = true;
      mockRepository.failureToReturn =
          CacheFailure(message: 'Cache write failed');
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<CacheFailure>());
      expect(error.failure.message, 'Cache write failed');
    });
  });

  group('ManageBookmarksUseCase - removeBookmark', () {
    test('should remove bookmark successfully with valid inputs', () async {
      // Arrange
      mockRepository.isBookmarked = true; // Already bookmarked
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<Success<void>>());
      expect(mockRepository.isVerseBookmarkedCallCount, 1);
      expect(mockRepository.removeBookmarkCallCount, 1);
    });

    test('should return ValidationFailure when verse is not bookmarked',
        () async {
      // Arrange
      mockRepository.isBookmarked = false; // Not bookmarked
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<ValidationFailure>());
      expect(
        error.failure.message,
        contains('is not bookmarked'),
      );
      expect(
          mockRepository.removeBookmarkCallCount, 0); // Should not call remove
    });

    test('should return InvalidInputFailure for invalid surah number',
        () async {
      // Arrange
      const surahNumber = 200;
      const verseNumber = 1;

      // Act
      final result = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<InvalidInputFailure>());
    });

    test('should return InvalidInputFailure for invalid verse number',
        () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = -1;

      // Act
      final result = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<InvalidInputFailure>());
    });

    test('should propagate repository failures', () async {
      // Arrange
      mockRepository.isBookmarked = true;
      mockRepository.shouldReturnError = true;
      mockRepository.failureToReturn =
          CacheFailure(message: 'Cache delete failed');
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<CacheFailure>());
    });
  });

  group('ManageBookmarksUseCase - toggleBookmark', () {
    test('should add bookmark when verse is not bookmarked', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 1;
      const verseNumber = 1;
      const note = 'Toggle test note';

      // Act
      final result = await useCase.toggleBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: note,
      );

      // Assert
      expect(result, isA<Success<bool>>());
      final success = result as Success<bool>;
      expect(success.data, true); // Now bookmarked
      expect(mockRepository.addBookmarkCallCount, 1);
      expect(mockRepository.removeBookmarkCallCount, 0);
    });

    test('should remove bookmark when verse is already bookmarked', () async {
      // Arrange
      mockRepository.isBookmarked = true;
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.toggleBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<Success<bool>>());
      final success = result as Success<bool>;
      expect(success.data, false); // Now unbookmarked
      expect(mockRepository.removeBookmarkCallCount, 1);
      expect(mockRepository.addBookmarkCallCount, 0);
    });

    test('should propagate check bookmark failure', () async {
      // Arrange
      mockRepository.shouldReturnError = true;
      mockRepository.failureToReturn = NetworkFailure(message: 'Network error');
      const surahNumber = 1;
      const verseNumber = 1;

      // Act
      final result = await useCase.toggleBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<bool>>());
      final error = result as ResultError<bool>;
      expect(error.failure, isA<NetworkFailure>());
    });

    test('should return error if add fails during toggle', () async {
      // Arrange
      mockRepository.isBookmarked = false;

      // Reset error state for isVerseBookmarked check
      mockRepository.shouldReturnError = false;

      const surahNumber = 1;
      const verseNumber = 1;

      // Act - first call to check bookmark status
      final checkResult =
          await mockRepository.isVerseBookmarked(surahNumber, verseNumber);
      expect(checkResult, isA<Success<bool>>());

      // Now set error for add operation
      mockRepository.shouldReturnError = true;
      mockRepository.failureToReturn = CacheFailure(message: 'Add failed');

      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      // Assert
      expect(result, isA<ResultError<void>>());
      final error = result as ResultError<void>;
      expect(error.failure, isA<CacheFailure>());
    });
  });

  group('ManageBookmarksUseCase - getAllBookmarks', () {
    test('should return all bookmarks successfully', () async {
      // Arrange
      final bookmark1 = BookmarkedVerse(
        surahNumber: 1,
        verseNumber: 1,
        surahName: 'Al-Fatiha',
        arabicText: 'بِسْمِ اللَّهِ',
        createdAt: DateTime(2024, 1, 1),
      );
      final bookmark2 = BookmarkedVerse(
        surahNumber: 2,
        verseNumber: 255,
        surahName: 'Al-Baqarah',
        arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
        createdAt: DateTime(2024, 1, 2),
      );
      mockRepository.bookmarksList = [bookmark1, bookmark2];

      // Act
      final result = await useCase.getAllBookmarks();

      // Assert
      expect(result, isA<Success<List<BookmarkedVerse>>>());
      final success = result as Success<List<BookmarkedVerse>>;
      expect(success.data.length, 2);
    });

    test('should return empty list when no bookmarks exist', () async {
      // Arrange
      mockRepository.bookmarksList = [];

      // Act
      final result = await useCase.getAllBookmarks();

      // Assert
      expect(result, isA<Success<List<BookmarkedVerse>>>());
      final success = result as Success<List<BookmarkedVerse>>;
      expect(success.data, isEmpty);
    });

    test('should sort bookmarks by date in descending order', () async {
      // Arrange
      final bookmark1 = BookmarkedVerse(
        surahNumber: 1,
        verseNumber: 1,
        surahName: 'Al-Fatiha',
        arabicText: 'بِسْمِ اللَّهِ',
        createdAt: DateTime(2024, 1, 1),
      );
      final bookmark2 = BookmarkedVerse(
        surahNumber: 2,
        verseNumber: 255,
        surahName: 'Al-Baqarah',
        arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
        createdAt: DateTime(2024, 1, 3),
      );
      final bookmark3 = BookmarkedVerse(
        surahNumber: 3,
        verseNumber: 1,
        surahName: 'Ali Imran',
        arabicText: 'الم',
        createdAt: DateTime(2024, 1, 2),
      );
      mockRepository.bookmarksList = [bookmark1, bookmark2, bookmark3];

      // Act
      final result = await useCase.getAllBookmarks(
        sortByDate: true,
        descending: true,
      );

      // Assert
      expect(result, isA<Success<List<BookmarkedVerse>>>());
      final success = result as Success<List<BookmarkedVerse>>;
      expect(success.data.length, 3);
      expect(success.data[0].surahNumber, 2); // Most recent (Jan 3)
      expect(success.data[1].surahNumber, 3); // Middle (Jan 2)
      expect(success.data[2].surahNumber, 1); // Oldest (Jan 1)
    });

    test('should sort bookmarks by date in ascending order', () async {
      // Arrange
      final bookmark1 = BookmarkedVerse(
        surahNumber: 1,
        verseNumber: 1,
        surahName: 'Al-Fatiha',
        arabicText: 'بِسْمِ اللَّهِ',
        createdAt: DateTime(2024, 1, 1),
      );
      final bookmark2 = BookmarkedVerse(
        surahNumber: 2,
        verseNumber: 255,
        surahName: 'Al-Baqarah',
        arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
        createdAt: DateTime(2024, 1, 3),
      );
      mockRepository.bookmarksList = [bookmark1, bookmark2];

      // Act
      final result = await useCase.getAllBookmarks(
        sortByDate: true,
        descending: false,
      );

      // Assert
      expect(result, isA<Success<List<BookmarkedVerse>>>());
      final success = result as Success<List<BookmarkedVerse>>;
      expect(success.data[0].surahNumber, 1); // Oldest first
      expect(success.data[1].surahNumber, 2); // Most recent last
    });

    test('should propagate repository failures', () async {
      // Arrange
      mockRepository.shouldReturnError = true;
      mockRepository.failureToReturn =
          CacheFailure(message: 'Failed to read bookmarks');

      // Act
      final result = await useCase.getAllBookmarks();

      // Assert
      expect(result, isA<ResultError<List<BookmarkedVerse>>>());
      final error = result as ResultError<List<BookmarkedVerse>>;
      expect(error.failure, isA<CacheFailure>());
      expect(error.failure.message, 'Failed to read bookmarks');
    });
  });

  group('ManageBookmarksUseCase - Edge Cases', () {
    test('should handle bookmark at maximum surah (114) and high verse number',
        () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 114; // An-Nas
      const verseNumber = 6; // Last verse of Quran

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: 'Last verse of Quran',
      );

      // Assert
      expect(result, isA<Success<void>>());
    });

    test('should handle multiple add/remove cycles', () async {
      // Arrange
      const surahNumber = 1;
      const verseNumber = 1;

      // Act & Assert - Add
      mockRepository.isBookmarked = false;
      final addResult1 = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      expect(addResult1, isA<Success<void>>());
      expect(mockRepository.bookmarksList.length, 1);

      // Remove
      mockRepository.isBookmarked = true;
      final removeResult = await useCase.removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      expect(removeResult, isA<Success<void>>());
      expect(mockRepository.bookmarksList.length, 0);

      // Add again
      mockRepository.isBookmarked = false;
      final addResult2 = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      expect(addResult2, isA<Success<void>>());
      expect(mockRepository.bookmarksList.length, 1);
    });

    test('should handle long notes', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 2;
      const verseNumber = 255;
      const longNote =
          'This is a very long note that might exceed typical storage limits. '
          'It contains multiple sentences and could potentially cause issues with database '
          'storage or UI display. We need to ensure the system handles this gracefully. '
          'Additional text to make it even longer and test the limits of the system.';

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: longNote,
      );

      // Assert
      expect(result, isA<Success<void>>());
      expect(mockRepository.bookmarksList.first.note, longNote);
    });

    test('should handle special characters in notes', () async {
      // Arrange
      mockRepository.isBookmarked = false;
      const surahNumber = 1;
      const verseNumber = 1;
      const specialNote =
          'Test with emojis 🕋 📿 ☪️ and Arabic: بسم الله الرحمن الرحيم';

      // Act
      final result = await useCase.addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: specialNote,
      );

      // Assert
      expect(result, isA<Success<void>>());
      expect(mockRepository.bookmarksList.first.note, specialNote);
    });
  });
}
