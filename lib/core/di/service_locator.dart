import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/quran_remote_datasource.dart';
import '../../data/repositories/quran_repository.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/get_surah_usecase.dart';
import '../../domain/usecases/manage_bookmarks_usecase.dart';
import '../../domain/usecases/get_surah_translations_usecase.dart';
import '../../domain/usecases/get_verse_translation_usecase.dart';
import '../../domain/usecases/get_available_translations_usecase.dart';
import '../../domain/usecases/get_verse_tafsir_usecase.dart';
import '../../domain/usecases/get_available_tafsirs_usecase.dart';
import '../../presentation/providers/bookmarks_provider.dart';
import '../../presentation/providers/surah_provider.dart';
import '../../presentation/providers/translation_provider.dart';
import '../../presentation/providers/tafsir_provider.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository.dart';
import '../../domain/repositories/community_repository_interface.dart';
import '../../domain/usecases/community/get_posts_usecase.dart';
import '../../domain/usecases/community/create_post_usecase.dart';
import '../../domain/usecases/community/toggle_like_post_usecase.dart';
import '../../domain/usecases/community/create_comment_usecase.dart';
import '../../domain/usecases/community/get_comments_usecase.dart';
import '../../services/hijri_calendar_service.dart';
import '../../domain/usecases/get_hijri_date_usecase.dart';
import '../../domain/usecases/get_islamic_events_usecase.dart';
import '../../presentation/providers/islamic_calendar_provider.dart';
import '../../presentation/providers/community_provider.dart';
import '../../presentation/providers/reading_stats_provider.dart';

/// GetIt service locator for dependency injection
/// Replaces manual DI with automatic dependency resolution
final getIt = GetIt.instance;

/// Setup all dependencies using GetIt
Future<void> setupDependencies() async {
  // External dependencies (singletons)
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Supabase Client
  getIt.registerLazySingleton<SupabaseClient>(() {
    return Supabase.instance.client;
  });

  // Data sources (singletons)
  getIt.registerLazySingleton<QuranRemoteDataSource>(
    () => QuranRemoteDataSource(client: getIt()),
  );

  // Repository (singleton with async initialization)
  getIt.registerLazySingletonAsync<QuranRepositoryInterface>(() async {
    final repository = QuranRepository(
      remoteDataSource: getIt<QuranRemoteDataSource>(),
      connectivity: getIt<Connectivity>(),
    );
    await repository.initialize();
    return repository;
  });

  // Wait for repository to initialize before continuing
  await getIt.isReady<QuranRepositoryInterface>();

  // Use cases (singletons)
  getIt.registerLazySingleton<GetSurahUseCase>(
    () => GetSurahUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<ManageBookmarksUseCase>(
    () => ManageBookmarksUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<GetSurahTranslationsUseCase>(
    () => GetSurahTranslationsUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<GetVerseTranslationUseCase>(
    () => GetVerseTranslationUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<GetAvailableTranslationsUseCase>(
    () => GetAvailableTranslationsUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<GetVerseTafsirUseCase>(
    () => GetVerseTafsirUseCase(getIt<QuranRepositoryInterface>()),
  );

  getIt.registerLazySingleton<GetAvailableTafsirsUseCase>(
    () => GetAvailableTafsirsUseCase(getIt<QuranRepositoryInterface>()),
  );

  // Providers (factories for proper disposal with ChangeNotifier)
  // Factories allow creating new instances when needed
  getIt.registerFactory<BookmarksProvider>(
    () => BookmarksProvider(getIt<ManageBookmarksUseCase>()),
  );

  getIt.registerFactory<SurahProvider>(
    () => SurahProvider(getIt<GetSurahUseCase>()),
  );

  getIt.registerFactory<TranslationProvider>(
    () => TranslationProvider(
      getSurahTranslationsUseCase: getIt<GetSurahTranslationsUseCase>(),
      getVerseTranslationUseCase: getIt<GetVerseTranslationUseCase>(),
      getAvailableTranslationsUseCase: getIt<GetAvailableTranslationsUseCase>(),
    ),
  );

  getIt.registerFactory<TafsirProvider>(
    () => TafsirProvider(
      getVerseTafsirUseCase: getIt<GetVerseTafsirUseCase>(),
      getAvailableTafsirsUseCase: getIt<GetAvailableTafsirsUseCase>(),
    ),
  );

  // Community Feature
  // Datasource
  getIt.registerLazySingleton<CommunityRemoteDataSource>(
    () => CommunityRemoteDataSourceImpl(supabaseClient: getIt()),
  );

  // Repository
  getIt.registerLazySingleton<CommunityRepositoryInterface>(
    () => CommunityRepository(
        remoteDataSource: getIt<CommunityRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton<GetPostsUseCase>(
    () => GetPostsUseCase(getIt<CommunityRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreatePostUseCase>(
    () => CreatePostUseCase(getIt<CommunityRepositoryInterface>()),
  );
  getIt.registerLazySingleton<ToggleLikePostUseCase>(
    () => ToggleLikePostUseCase(getIt<CommunityRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateCommentUseCase>(
    () => CreateCommentUseCase(getIt<CommunityRepositoryInterface>()),
  );
  getIt.registerLazySingleton<GetCommentsUseCase>(
    () => GetCommentsUseCase(getIt<CommunityRepositoryInterface>()),
  );

  // Provider
  getIt.registerFactory<CommunityProvider>(
    () => CommunityProvider(
      getPostsUseCase: getIt<GetPostsUseCase>(),
      createPostUseCase: getIt<CreatePostUseCase>(),
      toggleLikePostUseCase: getIt<ToggleLikePostUseCase>(),
      createCommentUseCase: getIt<CreateCommentUseCase>(),
      getCommentsUseCase: getIt<GetCommentsUseCase>(),
    ),
  );

  getIt.registerFactory<ReadingStatsProvider>(
    () => ReadingStatsProvider(),
  );

  // Islamic Calendar Feature
  // Services
  getIt.registerLazySingleton(() => HijriCalendarService());

  // Use Cases
  getIt.registerLazySingleton(() => GetHijriDateUseCase(getIt()));
  getIt.registerLazySingleton(() => GetIslamicEventsUseCase(getIt()));

  // Providers
  getIt.registerFactory(() => IslamicCalendarProvider(getIt(), getIt()));
}

/// Reset GetIt (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
