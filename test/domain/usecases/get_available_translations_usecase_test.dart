import 'package:flutter_test/flutter_test.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/usecases/get_available_translations_usecase.dart';
import 'package:salam/domain/repositories/quran_repository_interface.dart';
import 'package:salam/core/errors/failures.dart';

// Mock repository for testing
class MockQuranRepository implements QuranRepositoryInterface {
  bool shouldSucceed = true;
  List<TranslationInfo>? mockTranslations;
  Failure? mockFailure;

  @override
  Future<Result<List<TranslationInfo>>> getAvailableTranslations() async {
    if (!shouldSucceed) {
      return ResultError(
          mockFailure ?? NetworkFailure(message: 'Test failure'));
    }
    return Success(mockTranslations ??
        const [
          TranslationInfo(
              key: 'en.sahih',
              name: 'Sahih International',
              author: 'Sahih International',
              language: 'English',
              languageCode: 'en'),
          TranslationInfo(
              key: 'en.yusufali',
              name: 'Yusuf Ali',
              author: 'Abdullah Yusuf Ali',
              language: 'English',
              languageCode: 'en'),
        ]);
  }

  // Other required methods (not used in these tests)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GetAvailableTranslationsUseCase useCase;
  late MockQuranRepository mockRepository;

  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetAvailableTranslationsUseCase(mockRepository);
  });

  group('GetAvailableTranslationsUseCase', () {
    test('should return success with list of available translations', () async {
      // Arrange
      mockRepository.shouldSucceed = true;

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<Success<List<TranslationInfo>>>());
      final successResult = result as Success<List<TranslationInfo>>;
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
      expect(result, isA<ResultError<List<TranslationInfo>>>());
      final errorResult = result as ResultError<List<TranslationInfo>>;
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
      expect(result, isA<ResultError<List<TranslationInfo>>>());
      final errorResult = result as ResultError<List<TranslationInfo>>;
      expect(errorResult.failure, isA<ServerFailure>());
    });

    test('should return empty list when no translations are available',
        () async {
      // Arrange
      mockRepository.shouldSucceed = true;
      mockRepository.mockTranslations = const [];

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<Success<List<TranslationInfo>>>());
      final successResult = result as Success<List<TranslationInfo>>;
      expect(successResult.data, isEmpty);
    });

    test('should handle CacheFailure correctly', () async {
      // Arrange
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = CacheFailure(message: 'Cache error');

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isA<ResultError<List<TranslationInfo>>>());
      final errorResult = result as ResultError<List<TranslationInfo>>;
      expect(errorResult.failure, isA<CacheFailure>());
    });
  });
}
