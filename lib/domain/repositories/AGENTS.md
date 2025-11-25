# Domain Repositories - AGENTS.md

## Overview
Repository interfaces define the **contract** for data operations. They specify WHAT data operations are available, not HOW they're implemented. This is the boundary between domain (business logic) and data (implementation details).

**Key Principles**:
- Interfaces only - no implementation code
- Return `Result<T>` for all operations
- No framework dependencies (pure Dart)
- Comprehensive CRUD operations for all domain entities
- Documentation of expected behavior

## File

### `quran_repository_interface.dart`

**Core Components**:

#### 1. Result Type Definition
```dart
/// Result type for handling success/failure scenarios
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}
```

**Why `sealed class`**: Forces exhaustive pattern matching. Compiler ensures you handle both Success and ResultError cases.

**Usage**:
```dart
final result = await repository.getSurah(1);

// Compiler forces you to handle both cases
switch (result) {
  case Success<Surah>(:final data):
    print('Got surah: ${data.name}');
  case ResultError<Surah>(:final failure):
    print('Error: ${failure.message}');
}

// Or with if/is
if (result is Success<Surah>) {
  final surah = result.data;
} else if (result is ResultError<Surah>) {
  final error = result.failure;
}
```

---

#### 2. Repository Interface
```dart
abstract class QuranRepositoryInterface {
  // Surah operations
  Future<Result<List<Surah>>> getAllSurahs();
  Future<Result<Surah>> getSurah(int surahNumber);
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber);
  Future<Result<List<Verse>>> getVerses(int surahNumber, {int? startVerse, int? endVerse});

  // Search operations
  Future<Result<List<Verse>>> searchArabicText(String query);
  Future<Result<List<Verse>>> searchTranslation(String query, String translationKey);
  Future<Result<List<Surah>>> searchSurahs(String query);

  // Translation operations
  Future<Result<List<TranslationInfo>>> getAvailableTranslations();
  Future<Result<String>> getVerseTranslation(int surahNumber, int verseNumber, String translationKey);
  Future<Result<List<String>>> getSurahTranslations(int surahNumber, String translationKey);

  // Tafsir operations
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs();
  Future<Result<String>> getVerseTafsir(int surahNumber, int verseNumber, String tafsirKey);

  // Audio operations
  Future<Result<List<ReciterInfo>>> getAvailableReciters();
  Future<Result<String>> getVerseAudioUrl(int surahNumber, int verseNumber, String reciterKey);
  Future<Result<String>> getSurahAudioUrl(int surahNumber, String reciterKey);

  // Bookmark operations
  Future<Result<void>> addBookmark(int surahNumber, int verseNumber, String? note);
  Future<Result<void>> removeBookmark(int surahNumber, int verseNumber);
  Future<Result<List<Bookmark>>> getAllBookmarks();
  Future<Result<void>> updateBookmarkNote(int surahNumber, int verseNumber, String note);
  Future<Result<bool>> isVerseBookmarked(int surahNumber, int verseNumber);
  Future<Result<void>> clearAllBookmarks();

  // Reading progress operations
  Future<Result<void>> saveReadingProgress(int surahNumber, int verseNumber, int pageNumber);
  Future<Result<ReadingProgress?>> getReadingProgress();
  Future<Result<void>> clearReadingProgress();

  // Page operations (Mushaf mode)
  Future<Result<QuranPage>> getPage(int pageNumber);
  Future<Result<List<QuranPage>>> getPageRange(int startPage, int endPage);
  Future<Result<int>> getPageForVerse(int surahNumber, int verseNumber);

  // Juz operations
  Future<Result<List<JuzInfo>>> getAllJuz();
  Future<Result<JuzInfo>> getJuz(int juzNumber);
  Future<Result<List<QuranPage>>> getJuzPages(int juzNumber);

  // Statistics operations
  Future<Result<QuranStats>> getQuranStats();
  Future<Result<SurahStats>> getSurahStats(int surahNumber);
}
```

---

### Operation Categories

#### **1. SURAH OPERATIONS**
Core Quran text retrieval operations.

```dart
// Get all 114 surahs (lightweight, no verses)
Future<Result<List<Surah>>> getAllSurahs();

// Get complete surah with all verses
Future<Result<Surah>> getSurah(int surahNumber);

// Get single verse
Future<Result<Verse>> getVerse(int surahNumber, int verseNumber);

// Get verse range
Future<Result<List<Verse>>> getVerses(
  int surahNumber, {
  int? startVerse,  // If null, start from first verse
  int? endVerse,    // If null, end at last verse
});
```

**Expected Behavior**:
- `getSurah(0)` or `getSurah(115)` → `ResultError<InvalidInputFailure>`
- `getSurah(1)` → Al-Fatihah with 7 verses
- `getVerse(1, 999)` → `ResultError<VerseNotFoundFailure>`
- Network failure → `ResultError<NetworkFailure>` (but may return cached data)

**Usage Example**:
```dart
// In use case
final result = await repository.getSurah(1);

if (result is Success<Surah>) {
  final surah = result.data;
  print('${surah.englishName}: ${surah.numberOfAyahs} verses');
} else if (result is ResultError<Surah>) {
  print('Error: ${result.failure.message}');
}
```

---

#### **2. SEARCH OPERATIONS**
Full-text search across Quran content.

```dart
// Search Arabic text (e.g., 'الحمد')
Future<Result<List<Verse>>> searchArabicText(String query);

// Search in translation (e.g., 'mercy' in English)
Future<Result<List<Verse>>> searchTranslation(
  String query,
  String translationKey, // e.g., 'en.sahih'
);

// Search surah names (Arabic or English)
Future<Result<List<Surah>>> searchSurahs(String query);
```

**Expected Behavior**:
- Empty query → `ResultError<InvalidInputFailure>`
- No results → `Success<List<Verse>>([])` (empty list, not error)
- Invalid translation key → `ResultError<InvalidInputFailure>`

**Search Patterns**:
```dart
// Case-insensitive partial match
searchArabicText('الله')    // Matches 'بِسْمِ اللَّهِ'
searchSurahs('fat')          // Matches 'Al-Fatihah'
searchTranslation('lord', 'en.sahih') // Matches verses with 'Lord' or 'lord'
```

---

#### **3. TRANSLATION OPERATIONS**
Quran translations in multiple languages.

```dart
// Get list of available translations
Future<Result<List<TranslationInfo>>> getAvailableTranslations();

// Get translation for single verse
Future<Result<String>> getVerseTranslation(
  int surahNumber,
  int verseNumber,
  String translationKey, // e.g., 'en.sahih', 'ur.jalandhry'
);

// Get translations for entire surah
Future<Result<List<String>>> getSurahTranslations(
  int surahNumber,
  String translationKey,
);
```

**Translation Keys Format**: `{language}.{translator}`
- English: `en.sahih`, `en.pickthall`, `en.yusufali`
- Urdu: `ur.jalandhry`, `ur.qadri`
- Indonesian: `id.indonesian`

**TranslationInfo Model**:
```dart
class TranslationInfo {
  final String key;           // 'en.sahih'
  final String language;      // 'English'
  final String translator;    // 'Sahih International'
  final String? description;
}
```

---

#### **4. TAFSIR OPERATIONS**
Quran commentary/interpretation.

```dart
// Get available tafsir sources
Future<Result<List<TafsirInfo>>> getAvailableTafsirs();

// Get tafsir for specific verse
Future<Result<String>> getVerseTafsir(
  int surahNumber,
  int verseNumber,
  String tafsirKey, // e.g., 'ar.muyassar', 'en.kathir'
);
```

**Tafsir Keys**: Similar to translation keys
- Arabic: `ar.muyassar`, `ar.jalalayn`
- English: `en.kathir`

**TafsirInfo Model**:
```dart
class TafsirInfo {
  final String key;
  final String language;
  final String name;
  final String? author;
}
```

---

#### **5. AUDIO OPERATIONS**
Quranic recitations.

```dart
// Get available reciters
Future<Result<List<ReciterInfo>>> getAvailableReciters();

// Get audio URL for single verse
Future<Result<String>> getVerseAudioUrl(
  int surahNumber,
  int verseNumber,
  String reciterKey, // e.g., 'ar.alafasy'
);

// Get audio URL for entire surah
Future<Result<String>> getSurahAudioUrl(
  int surahNumber,
  String reciterKey,
);
```

**Reciter Keys**: `{language}.{reciter_name}`
- `ar.alafasy` - Mishary Al-Afasy
- `ar.abdulbasit` - Abdul Basit
- `ar.minshawi` - Minshawi

**ReciterInfo Model**:
```dart
class ReciterInfo {
  final String key;
  final String name;
  final String? style; // 'Murattal', 'Mujawwad'
  final String audioFormat; // 'mp3', 'ogg'
}
```

**Audio URLs**: Typically CDN links
```
https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3
```

---

#### **6. BOOKMARK OPERATIONS**
User bookmark management.

```dart
// Add bookmark
Future<Result<void>> addBookmark(
  int surahNumber,
  int verseNumber,
  String? note, // Optional user note
);

// Remove bookmark
Future<Result<void>> removeBookmark(int surahNumber, int verseNumber);

// Get all bookmarks (sorted by creation date)
Future<Result<List<Bookmark>>> getAllBookmarks();

// Update bookmark note
Future<Result<void>> updateBookmarkNote(
  int surahNumber,
  int verseNumber,
  String note,
);

// Check if verse is bookmarked
Future<Result<bool>> isVerseBookmarked(int surahNumber, int verseNumber);

// Clear all bookmarks
Future<Result<void>> clearAllBookmarks();
```

**Bookmark Model**:
```dart
class Bookmark {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String verseText;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Expected Behavior**:
- Adding duplicate bookmark → `ResultError<ValidationFailure>`
- Removing non-existent bookmark → `ResultError<ValidationFailure>`
- `getAllBookmarks()` on empty → `Success<List<Bookmark>>([])` (empty list)

---

#### **7. READING PROGRESS OPERATIONS**
Track user's last read location.

```dart
// Save progress
Future<Result<void>> saveReadingProgress(
  int surahNumber,
  int verseNumber,
  int pageNumber,
);

// Get current progress (null if none)
Future<Result<ReadingProgress?>> getReadingProgress();

// Clear progress
Future<Result<void>> clearReadingProgress();
```

**ReadingProgress Model**:
```dart
class ReadingProgress {
  final int surahNumber;
  final int verseNumber;
  final int pageNumber;
  final String surahName;
  final DateTime lastReadAt;
}
```

---

#### **8. PAGE OPERATIONS (Mushaf Mode)**
Quran organized by physical Mushaf pages (604 pages).

```dart
// Get single page
Future<Result<QuranPage>> getPage(int pageNumber); // 1-604

// Get page range
Future<Result<List<QuranPage>>> getPageRange(int startPage, int endPage);

// Find page containing verse
Future<Result<int>> getPageForVerse(int surahNumber, int verseNumber);
```

**QuranPage Structure**: See `lib/domain/entities/AGENTS.md`

**Usage**:
```dart
// Get first page (Al-Fatihah)
final result = await repository.getPage(1);

if (result is Success<QuranPage>) {
  final page = result.data;
  print('Page ${page.pageNumber}, Juz ${page.juzNumber}');
  print('${page.ayahs.length} verses on this page');
}

// Find which page contains Al-Baqarah verse 255 (Ayat al-Kursi)
final pageResult = await repository.getPageForVerse(2, 255);
if (pageResult is Success<int>) {
  print('Ayat al-Kursi is on page ${pageResult.data}');
}
```

---

#### **9. JUZ OPERATIONS**
Quran divided into 30 Juz (parts).

```dart
// Get all 30 Juz info
Future<Result<List<JuzInfo>>> getAllJuz();

// Get specific Juz info
Future<Result<JuzInfo>> getJuz(int juzNumber); // 1-30

// Get all pages in a Juz
Future<Result<List<QuranPage>>> getJuzPages(int juzNumber);
```

**JuzInfo Model**:
```dart
class JuzInfo {
  final int number;
  final String name; // Arabic name
  final int startPage;
  final int endPage;
  final int startSurah;
  final int startVerse;
  final int endSurah;
  final int endVerse;
}
```

---

#### **10. STATISTICS OPERATIONS**
Quran metadata and statistics.

```dart
// Overall Quran stats
Future<Result<QuranStats>> getQuranStats();

// Per-surah stats
Future<Result<SurahStats>> getSurahStats(int surahNumber);
```

**QuranStats Model**:
```dart
class QuranStats {
  final int totalSurahs;       // 114
  final int totalVerses;       // 6236
  final int totalPages;        // 604
  final int totalJuz;          // 30
  final int meccanSurahs;      // 86
  final int medinanSurahs;     // 28
}
```

**SurahStats Model**:
```dart
class SurahStats {
  final int number;
  final int numberOfAyahs;
  final int numberOfWords;
  final int numberOfLetters;
  final int startPage;
  final int endPage;
  final int juzNumber;
  final List<int> sajdaVerses; // Verses requiring prostration
}
```

---

## Implementation Contract

### What Implementations Must Do

**1. Error Handling**: Never throw exceptions. Convert all errors to `Failure` objects wrapped in `ResultError`.

**2. Caching**: Prefer cached data when available. Only fetch from network if cache is empty or expired.

**3. Offline Support**: Return cached data even if network is unavailable.

**4. Data Validation**: Validate all inputs before processing.

**5. Logging**: Log all operations for debugging.

### Expected Failure Types

| Operation Failed | Failure Type |
|-----------------|--------------|
| Network unavailable | `NetworkFailure` |
| API returns 500 | `ServerFailure` |
| Request timeout | `TimeoutFailure` |
| Cache read error | `CacheFailure` |
| Invalid input | `InvalidInputFailure` |
| Verse not found | `VerseNotFoundFailure` |
| Surah not found | `SurahNotFoundFailure` |
| Bookmark exists | `ValidationFailure` |

See `lib/core/errors/AGENTS.md` for complete failure hierarchy.

---

## Testing Repository Interface

### Mock Repository for Tests
```dart
class MockQuranRepository extends Mock implements QuranRepositoryInterface {}

void main() {
  late MockQuranRepository mockRepository;
  
  setUp(() {
    mockRepository = MockQuranRepository();
  });
  
  test('should return surah when repository succeeds', () async {
    // Arrange
    when(mockRepository.getSurah(1)).thenAnswer(
      (_) async => Success(validSurah),
    );
    
    // Act
    final result = await mockRepository.getSurah(1);
    
    // Assert
    expect(result, isA<Success<Surah>>());
    expect((result as Success<Surah>).data.number, 1);
  });
  
  test('should return error when repository fails', () async {
    when(mockRepository.getSurah(999)).thenAnswer(
      (_) async => ResultError(SurahNotFoundFailure(message: '...')),
    );
    
    final result = await mockRepository.getSurah(999);
    
    expect(result, isA<ResultError<Surah>>());
  });
}
```

---

## Common Patterns

### Pattern 1: Exhaustive Result Handling
```dart
final result = await repository.getSurah(1);

return switch (result) {
  Success<Surah>(:final data) => processData(data),
  ResultError<Surah>(:final failure) => handleError(failure),
};
```

### Pattern 2: Early Return on Error
```dart
final surahResult = await repository.getSurah(1);
if (surahResult is ResultError<Surah>) {
  return ResultError(surahResult.failure);
}

final surah = (surahResult as Success<Surah>).data;
// Continue with surah
```

### Pattern 3: Composing Results
```dart
final surahResult = await repository.getSurah(1);
final translationResult = await repository.getSurahTranslations(1, 'en.sahih');

if (surahResult is Success && translationResult is Success) {
  return combineResults(surahResult.data, translationResult.data);
}
// Handle errors
```

---

## Common Pitfalls

### ❌ Pitfall 1: Implementing in Interface
```dart
// ❌ WRONG - has implementation
abstract class QuranRepositoryInterface {
  Future<Result<Surah>> getSurah(int surahNumber) async {
    return Success(/* ... */); // NO! This is implementation!
  }
}

// ✅ CORRECT - interface only
abstract class QuranRepositoryInterface {
  Future<Result<Surah>> getSurah(int surahNumber);
}
```

### ❌ Pitfall 2: Not Using Result Type
```dart
// ❌ WRONG - can throw exception
abstract class QuranRepositoryInterface {
  Future<Surah> getSurah(int surahNumber);
}

// ✅ CORRECT - uses Result
abstract class QuranRepositoryInterface {
  Future<Result<Surah>> getSurah(int surahNumber);
}
```

### ❌ Pitfall 3: Framework Dependencies
```dart
// ❌ WRONG - depends on Flutter
import 'package:flutter/material.dart';

abstract class QuranRepositoryInterface {
  Future<Result<Widget>> getWidget(); // NO!
}

// ✅ CORRECT - pure Dart
abstract class QuranRepositoryInterface {
  Future<Result<Surah>> getSurah(int surahNumber);
}
```

---

**Related Documentation**:
- See `lib/domain/AGENTS.md` for domain layer overview
- See `lib/domain/usecases/AGENTS.md` for repository usage
- See `lib/data/repositories/AGENTS.md` for implementation details
- See `lib/core/errors/AGENTS.md` for failure types
