import '../../core/utils/result.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for getting list of available tafsir sources
///
/// Business Rules:
/// - Always returns the available tafsir sources
/// - No validation needed as this is a simple query
class GetAvailableTafsirsUseCase {
  final QuranRepositoryInterface repository;

  const GetAvailableTafsirsUseCase(this.repository);

  /// Execute the use case
  ///
  /// Returns Result<List<TafsirInfo>> containing all available tafsir sources
  Future<Result<List<TafsirInfo>>> execute() async {
    return await repository.getAvailableTafsirs();
  }
}
