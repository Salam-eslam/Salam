import '../../core/utils/result.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for getting list of available translations
///
/// Business Rules:
/// - Always returns the available translations
/// - No validation needed as this is a simple query
class GetAvailableTranslationsUseCase {
  final QuranRepositoryInterface repository;

  const GetAvailableTranslationsUseCase(this.repository);

  /// Execute the use case
  ///
  /// Returns Result<List<TranslationInfo>> containing all available translations
  Future<Result<List<TranslationInfo>>> execute() async {
    return await repository.getAvailableTranslations();
  }
}
