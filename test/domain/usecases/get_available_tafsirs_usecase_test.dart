import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/usecases/get_available_tafsirs_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock repository for testing
class MockQuranRepository implements QuranRepositoryInterface {
  bool shouldSucceed = true;
  List<TafsirInfo>? mockTafsirs;
  Failure? mockFailure;

  @override
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs() async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTafsirs ??
        const [
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
        ]);
  }

  // Other required methods (not used in these tests)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetAvailableTafsirsUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetAvailableTafsirsUseCase(mockRepository);
  });

  group('GetAvailableTafsirsUseCase', () {
    test('should return success with list of available tafsirs', () async {
      // Arrange
      mockRepository.shouldSucceed = true;

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<Success<List<TafsirInfo>>>());
      final successResult = result as Success<List<TafsirInfo>>;
      expect(successResult.data.length, greaterThanOrEqualTo(2));
    });

    test('should return NetworkFailure when repository fails', () async {
      // Arrange
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure =
          NetworkFailure(message: 'No internet connection');

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<ResultError<List<TafsirInfo>>>());
      final errorResult = result as ResultError<List<TafsirInfo>>;
      expect(errorResult.failure, isA<NetworkFailure>());
    });

    test('should return ServerFailure when repository returns server error',
        () async {
      // Arrange
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure =
          ServerFailure(message: 'Server error occurred');

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<ResultError<List<TafsirInfo>>>());
      final errorResult = result as ResultError<List<TafsirInfo>>;
      expect(errorResult.failure, isA<ServerFailure>());
    });

    test('should return empty list when no tafsirs are available', () async {
      // Arrange
      mockRepository.shouldSucceed = true;
      mockRepository.mockTafsirs = const [];

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<Success<List<TafsirInfo>>>());
      final successResult = result as Success<List<TafsirInfo>>;
      expect(successResult.data, isEmpty);
    });

    test('should handle CacheFailure correctly', () async {
      // Arrange
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = CacheFailure(message: 'Cache error');

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<ResultError<List<TafsirInfo>>>());
      final errorResult = result as ResultError<List<TafsirInfo>>;
      expect(errorResult.failure, isA<CacheFailure>());
    });
  });
}
