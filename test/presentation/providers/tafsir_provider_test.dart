import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/presentation/providers/tafsir_provider.dart';
import 'package:salam/domain/usecases/get_verse_tafsir_usecase.dart';
import 'package:salam/domain/usecases/get_available_tafsirs_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock use cases for testing
class MockGetVerseTafsirUseCase extends GetVerseTafsirUseCase {
  bool shouldSucceed = true;
  String? mockTafsir;
  Failure? mockFailure;

  MockGetVerseTafsirUseCase(super.repository);

  @override
  Future<Result<String>> execute({
    required int surahNumber,
    required int verseNumber,
    required String tafsirKey,
  }) async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTafsir ?? 'Tafsir explanation text');
  }
}

class MockGetAvailableTafsirsUseCase extends GetAvailableTafsirsUseCase {
  bool shouldSucceed = true;
  List<TafsirInfo>? mockTafsirs;
  Failure? mockFailure;

  MockGetAvailableTafsirsUseCase(super.repository);

  @override
  Future<Result<List<TafsirInfo>>> execute() async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTafsirs ?? const []);
  }
}

// Minimal mock repository (not used directly in provider tests)
class MockQuranRepository implements QuranRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TafsirProvider provider;
  late MockGetVerseTafsirUseCase mockGetVerseTafsir;
  late MockGetAvailableTafsirsUseCase mockGetAvailableTafsirs;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    mockGetVerseTafsir = MockGetVerseTafsirUseCase(mockRepository);
    mockGetAvailableTafsirs = MockGetAvailableTafsirsUseCase(mockRepository);

    provider = TafsirProvider(
      getVerseTafsirUseCase: mockGetVerseTafsir,
      getAvailableTafsirsUseCase: mockGetAvailableTafsirs,
    );
  });

  group('TafsirProvider', () {
    group('Initial State', () {
      test('should have correct initial state', () {
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.currentTafsirKey, isNull);
        expect(provider.availableTafsirs, isNull);
      });
    });

    group('loadVerseTafsir', () {
      test('should set loading state to true during execution', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;
        bool wasLoading = false;

        provider.addListener(() {
          if (provider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(wasLoading, isTrue);
      });

      test('should load tafsir successfully and cache it', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;
        mockGetVerseTafsir.mockTafsir =
            'Praise be to Allah, Lord of all the worlds.';

        // Act
        final result = await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('Praise'));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.currentTafsirKey, equals('en.muyassar'));
      });

      test('should cache tafsir for subsequent retrieval', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;
        mockGetVerseTafsir.mockTafsir = 'Cached tafsir text';

        // Act
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');
        final cachedResult = provider.getTafsir(1, 1);

        // Assert
        expect(cachedResult, isNotNull);
        expect(cachedResult, equals('Cached tafsir text'));
      });

      test('should handle failure and set error state', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = false;
        mockGetVerseTafsir.mockFailure =
            NetworkFailure(message: 'No internet connection');

        // Act
        final result = await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(result, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('No internet connection'));
      });

      test('should notify listeners when state changes', () async {
        // Arrange
        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        mockGetVerseTafsir.shouldSucceed = true;

        // Act
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert - should notify at least twice (loading start, loading end)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('should clear previous error on new successful load', () async {
        // Arrange - First load fails
        mockGetVerseTafsir.shouldSucceed = false;
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');
        expect(provider.error, isNotNull);

        // Act - Second load succeeds
        mockGetVerseTafsir.shouldSucceed = true;
        await provider.loadVerseTafsir(1, 2, 'en.muyassar');

        // Assert
        expect(provider.error, isNull);
      });

      test('should handle empty tafsir text', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;
        mockGetVerseTafsir.mockTafsir = '';

        // Act
        final result = await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(result, isEmpty);
      });

      test('should update currentTafsirKey when loading', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;

        // Act
        await provider.loadVerseTafsir(1, 1, 'ar.muyassar');

        // Assert
        expect(provider.currentTafsirKey, equals('ar.muyassar'));
      });
    });

    group('getTafsir', () {
      test('should return null for non-cached tafsir', () {
        // Act
        final result = provider.getTafsir(1, 1);

        // Assert
        expect(result, isNull);
      });

      test('should return cached tafsir', () async {
        // Arrange - Load tafsir first
        mockGetVerseTafsir.shouldSucceed = true;
        mockGetVerseTafsir.mockTafsir = 'Cached tafsir';
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Act
        final result = provider.getTafsir(1, 1);

        // Assert
        expect(result, equals('Cached tafsir'));
      });

      test('should distinguish between different verses', () async {
        // Arrange - Load tafsirs for different verses
        mockGetVerseTafsir.shouldSucceed = true;

        mockGetVerseTafsir.mockTafsir = 'Tafsir for verse 1';
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        mockGetVerseTafsir.mockTafsir = 'Tafsir for verse 2';
        await provider.loadVerseTafsir(1, 2, 'en.muyassar');

        // Act & Assert
        expect(provider.getTafsir(1, 1), equals('Tafsir for verse 1'));
        expect(provider.getTafsir(1, 2), equals('Tafsir for verse 2'));
      });
    });

    group('hasTafsir', () {
      test('should return false for non-cached tafsir', () {
        // Act
        final result = provider.hasTafsir(1, 1);

        // Assert
        expect(result, isFalse);
      });

      test('should return true for cached tafsir', () async {
        // Arrange - Load tafsir first
        mockGetVerseTafsir.shouldSucceed = true;
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Act
        final result = provider.hasTafsir(1, 1);

        // Assert
        expect(result, isTrue);
      });

      test('should correctly identify cached vs non-cached verses', () async {
        // Arrange - Load tafsir for verse 1 only
        mockGetVerseTafsir.shouldSucceed = true;
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Act & Assert
        expect(provider.hasTafsir(1, 1), isTrue);
        expect(provider.hasTafsir(1, 2), isFalse);
        expect(provider.hasTafsir(2, 1), isFalse);
      });
    });

    group('loadAvailableTafsirs', () {
      test('should load available tafsirs successfully', () async {
        // Arrange
        mockGetAvailableTafsirs.shouldSucceed = true;
        mockGetAvailableTafsirs.mockTafsirs = const [
          TafsirInfo(
              key: 'en.muyassar',
              name: 'Al-Muyassar',
              author: 'King Fahad Quran Complex',
              language: 'English',
              languageCode: 'en'),
          TafsirInfo(
              key: 'ar.muyassar',
              name: 'Al-Muyassar',
              author: 'King Fahad Quran Complex',
              language: 'Arabic',
              languageCode: 'ar'),
        ];

        // Act
        await provider.loadAvailableTafsirs();

        // Assert
        expect(provider.availableTafsirs, isNotNull);
        expect(provider.availableTafsirs!.length, equals(2));
        expect(provider.availableTafsirs![0].key, equals('en.muyassar'));
      });

      test('should handle failure when loading available tafsirs', () async {
        // Arrange
        mockGetAvailableTafsirs.shouldSucceed = false;

        // Act
        await provider.loadAvailableTafsirs();

        // Assert - loadAvailableTafsirs doesn't set error, it just logs
        // The provider won't have an error, but availableTafsirs will be null
        expect(provider.availableTafsirs, isNull);
      });

      test('should not update loading state during execution', () async {
        // Arrange
        mockGetAvailableTafsirs.shouldSucceed = true;
        bool wasLoading = false;

        provider.addListener(() {
          if (provider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await provider.loadAvailableTafsirs();

        // Assert - loadAvailableTafsirs doesn't update loading state
        expect(wasLoading, isFalse);
        expect(provider.isLoading, isFalse);
      });
    });

    group('clearTafsirs', () {
      test('should clear all cached tafsirs and reset state', () async {
        // Arrange - Load some tafsirs first
        mockGetVerseTafsir.shouldSucceed = true;
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');
        await provider.loadVerseTafsir(1, 2, 'en.muyassar');
        expect(provider.hasTafsir(1, 1), isTrue);
        expect(provider.hasTafsir(1, 2), isTrue);

        // Act
        provider.clearTafsirs();

        // Assert
        expect(provider.hasTafsir(1, 1), isFalse);
        expect(provider.hasTafsir(1, 2), isFalse);
        expect(provider.error, isNull);
        expect(provider.currentTafsirKey, isNull);
      });

      test('should notify listeners when clearing', () {
        // Arrange
        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Act
        provider.clearTafsirs();

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('Error Handling', () {
      test('should handle InvalidInputFailure', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = false;
        mockGetVerseTafsir.mockFailure =
            InvalidInputFailure(message: 'Invalid verse number');

        // Act
        await provider.loadVerseTafsir(999, 1, 'en.muyassar');

        // Assert
        expect(provider.error, contains('Invalid verse number'));
      });

      test('should handle CacheFailure', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = false;
        mockGetVerseTafsir.mockFailure =
            CacheFailure(message: 'Cache write failed');

        // Act
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(provider.error, contains('Cache write failed'));
      });

      test('should handle ServerFailure', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = false;
        mockGetVerseTafsir.mockFailure =
            ServerFailure(message: 'Server error 503');

        // Act
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        // Assert
        expect(provider.error, contains('Server error 503'));
      });
    });

    group('Cache Management', () {
      test('should maintain separate caches for different surahs', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;

        mockGetVerseTafsir.mockTafsir = 'Surah 1 Verse 1';
        await provider.loadVerseTafsir(1, 1, 'en.muyassar');

        mockGetVerseTafsir.mockTafsir = 'Surah 2 Verse 1';
        await provider.loadVerseTafsir(2, 1, 'en.muyassar');

        // Act & Assert
        expect(provider.getTafsir(1, 1), equals('Surah 1 Verse 1'));
        expect(provider.getTafsir(2, 1), equals('Surah 2 Verse 1'));
      });

      test('should cache multiple verses independently', () async {
        // Arrange
        mockGetVerseTafsir.shouldSucceed = true;

        // Load multiple verses
        for (int i = 1; i <= 5; i++) {
          mockGetVerseTafsir.mockTafsir = 'Tafsir for verse $i';
          await provider.loadVerseTafsir(1, i, 'en.muyassar');
        }

        // Act & Assert - Verify all are cached
        for (int i = 1; i <= 5; i++) {
          expect(provider.hasTafsir(1, i), isTrue);
          expect(provider.getTafsir(1, i), equals('Tafsir for verse $i'));
        }
      });
    });
  });
}
