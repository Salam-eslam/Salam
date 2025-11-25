# Data Repositories - AGENTS.md

## Overview
Repository implementations bridge domain (interfaces) and data (sources/models). Single file implementing all Quran data operations with three-tier caching strategy.

## File

### `quran_repository.dart`
**Purpose**: Implements `QuranRepositoryInterface` with offline-first caching.

**Core Structure**:
```dart
class QuranRepository implements QuranRepositoryInterface {
  final QuranRemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  
  late Box<CachedSurah> _surahBox;
  late Box<Bookmark> _bookmarkBox;
  late Box<ReadingProgress> _readingProgressBox;
  
  QuranRepository({
    required this.remoteDataSource,
    required this.connectivity,
  });
  
  Future<void> initialize() async {
    _surahBox = await Hive.openBox<CachedSurah>('surahs');
    _bookmarkBox = await Hive.openBox<Bookmark>('bookmarks');
    _readingProgressBox = await Hive.openBox<ReadingProgress>('reading_progress');
  }
}
```

---

## Three-Tier Caching Strategy

**Tier 1: Fresh Cache** → Return immediately
**Tier 2: Expired Cache + No Network** → Return stale cache
**Tier 3: Network Available** → Fetch from API, update cache

**Implementation**:
```dart
@override
Future<Result<Surah>> getSurah(int surahNumber) async {
  try {
    // Tier 1: Check fresh cache
    final cached = _surahBox.get(surahNumber);
    if (cached != null && !cached.isExpired) {
      return Success(_convertCachedSurahToEntity(cached));
    }
    
    // Tier 2: Check network connectivity
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      // Return expired cache if available
      if (cached != null) {
        return Success(_convertCachedSurahToEntity(cached));
      }
      return ResultError(
        NetworkFailure(message: 'No internet connection and no cached data'),
      );
    }
    
    // Tier 3: Fetch from API
    final data = await remoteDataSource.getSurah(surahNumber);
    final surah = _convertApiDataToEntity(data);
    
    // Cache it
    await _cacheSurah(surah);
    
    return Success(surah);
  } on Failure catch (failure) {
    return ResultError(failure);
  } catch (e) {
    return ResultError(ServerFailure(message: '$e'));
  }
}
```

**Cache TTL**: 30 days for Quran data (never changes)
```dart
bool get isExpired => DateTime.now().difference(cachedAt).inDays > 30;
```

---

## Key Operations

### 1. Surah Operations
```dart
@override
Future<Result<List<Surah>>> getAllSurahs() async {
  // Check if all 114 surahs are cached
  if (_surahBox.length == 114 && _allCacheFresh()) {
    return Success(_surahBox.values.map(_convertCachedSurahToEntity).toList());
  }
  
  // Fetch from API
  final data = await remoteDataSource.getAllSurahs();
  // ... convert and cache
}
```

### 2. Bookmark Operations
```dart
@override
Future<Result<void>> addBookmark(int surahNumber, int verseNumber, String? note) async {
  // Check for duplicates
  final existingKey = '${surahNumber}_$verseNumber';
  if (_bookmarkBox.containsKey(existingKey)) {
    return ResultError(
      ValidationFailure(message: 'Bookmark already exists'),
    );
  }
  
  // Fetch verse text
  final verseResult = await getVerse(surahNumber, verseNumber);
  if (verseResult is ResultError) return ResultError(verseResult.failure);
  
  final verse = (verseResult as Success<Verse>).data;
  
  // Save bookmark
  final bookmark = Bookmark(
    surahNumber: surahNumber,
    surahName: verse.surahName,
    ayahNumber: verseNumber,
    text: verse.arabicText,
    note: note,
  );
  
  await _bookmarkBox.put(existingKey, bookmark);
  return const Success(null);
}

@override
Future<Result<List<Bookmark>>> getAllBookmarks() async {
  final bookmarks = _bookmarkBox.values.toList();
  bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return Success(bookmarks);
}
```

### 3. Reading Progress
```dart
@override
Future<Result<void>> saveReadingProgress(int surahNumber, int verseNumber, int pageNumber) async {
  final progress = ReadingProgress(
    surahNumber: surahNumber,
    ayahNumber: verseNumber,
    pageNumber: pageNumber,
    lastReadAt: DateTime.now(),
  );
  
  await _readingProgressBox.put('current', progress);
  return const Success(null);
}

@override
Future<Result<ReadingProgress?>> getReadingProgress() async {
  final progress = _readingProgressBox.get('current');
  return Success(progress);
}
```

### 4. Search Operations
```dart
@override
Future<Result<List<Verse>>> searchArabicText(String query) async {
  if (query.isEmpty) {
    return ResultError(
      InvalidInputFailure(message: 'Search query cannot be empty'),
    );
  }
  
  try {
    // Search in cached surahs first
    final cachedResults = _searchInCache(query);
    if (cachedResults.isNotEmpty) {
      return Success(cachedResults);
    }
    
    // Search via API
    final data = await remoteDataSource.searchVerses(query);
    final verses = data.map(_convertToVerse).toList();
    return Success(verses);
  } on Failure catch (failure) {
    return ResultError(failure);
  }
}
```

---

## Conversion Methods

**Model → Entity**:
```dart
Surah _convertCachedSurahToEntity(CachedSurah cached) {
  return Surah(
    number: cached.number,
    name: cached.name,
    englishName: cached.englishName,
    englishNameTranslation: '', // Not cached
    revelationType: cached.revelationType,
    numberOfAyahs: cached.numberOfAyahs,
    verses: cached.ayahs.map((ayah) => Verse(
      number: ayah.number,
      numberInSurah: ayah.numberInSurah,
      arabicText: ayah.text,
      translation: null,
      transliteration: null,
      tafsir: null,
      isBookmarked: false,
      lastReadAt: null,
    )).toList(),
  );
}
```

**Entity → Model**:
```dart
CachedSurah _convertSurahToCached(Surah surah) {
  return CachedSurah(
    number: surah.number,
    name: surah.name,
    englishName: surah.englishName,
    revelationType: surah.revelationType,
    numberOfAyahs: surah.numberOfAyahs,
    ayahs: surah.verses.map((verse) => CachedAyah(
      number: verse.number,
      text: verse.arabicText,
      numberInSurah: verse.numberInSurah,
    )).toList(),
    cachedAt: DateTime.now(),
  );
}
```

---

## Connectivity Check

```dart
Future<bool> _hasInternetConnection() async {
  final connectivityResult = await connectivity.checkConnectivity();
  
  if (connectivityResult == ConnectivityResult.none) {
    return false;
  }
  
  // Additional check: ping API
  try {
    final result = await http.head(
      Uri.parse(AppConstants.quranApiBaseUrl),
    ).timeout(const Duration(seconds: 5));
    return result.statusCode == 200;
  } catch (_) {
    return false;
  }
}
```

---

## Testing

```dart
test('should return cached surah when cache is fresh', () async {
  // Arrange
  when(mockBox.get(1)).thenReturn(freshCachedSurah);
  
  // Act
  final result = await repository.getSurah(1);
  
  // Assert
  expect(result, isA<Success<Surah>>());
  verifyNever(mockDataSource.getSurah(any)); // Didn't hit API
});

test('should fetch from API when cache is expired', () async {
  when(mockBox.get(1)).thenReturn(expiredCachedSurah);
  when(mockConnectivity.checkConnectivity()).thenAnswer(
    (_) async => ConnectivityResult.wifi,
  );
  when(mockDataSource.getSurah(1)).thenAnswer(
    (_) async => validApiData,
  );
  
  final result = await repository.getSurah(1);
  
  expect(result, isA<Success<Surah>>());
  verify(mockDataSource.getSurah(1)).called(1);
});
```

---

**Related Documentation**:
- See `lib/data/AGENTS.md` for data layer overview
- See `lib/data/datasources/AGENTS.md` for API client
- See `lib/data/models/AGENTS.md` for cache models
- See `lib/domain/repositories/AGENTS.md` for interface contract
