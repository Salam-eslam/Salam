# Domain Layer - AGENTS.md

## Overview
The `domain` layer is the **core business logic** of the application, following Clean Architecture principles. It contains:
- **Entities**: Pure business objects with no framework dependencies
- **Use Cases**: Encapsulated business operations
- **Repository Interfaces**: Contracts for data access (implementation in `data` layer)

**Critical Rule**: Domain layer has **ZERO dependencies** on outer layers (data, presentation, services). Only depends on Dart SDK.

## Directory Structure
```
domain/
├── entities/          # Pure business objects (Surah, Verse, PrayerTimes, etc.)
├── usecases/          # Business logic operations (GetSurahUseCase, ManageBookmarksUseCase)
└── repositories/      # Repository interfaces (contracts only, no implementation)
```

## Core Concepts

### 1. Entities (Business Objects)
Pure Dart classes representing core business concepts. **No JSON serialization, no Hive annotations, no Flutter dependencies**.

#### Example: `entities/surah_entity.dart`
```dart
class Surah {
  final int number;
  final String name;
  final String englishName;
  final String revelationType; // "Meccan" or "Medinan"
  final int numberOfAyahs;
  final List<Verse> verses;
  
  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.verses,
  });
  
  // Business logic methods
  bool get isMeccan => revelationType.toLowerCase() == 'meccan';
  bool get isMedinan => revelationType.toLowerCase() == 'medinan';
  List<Verse> get bookmarkedVerses => verses.where((v) => v.isBookmarked).toList();
  Verse? getVerse(int verseNumber) => verses.firstWhere((v) => v.number == verseNumber);
}

class Verse {
  final int number;
  final String arabicText;
  final String? translation;
  final String? tafsir;
  final bool isBookmarked;
  final DateTime? lastRead;
  
  const Verse({
    required this.number,
    required this.arabicText,
    this.translation,
    this.tafsir,
    this.isBookmarked = false,
    this.lastRead,
  });
  
  int get wordCount => arabicText.split(' ').length;
}
```

**Entity Characteristics**:
- Immutable (all fields `final`, constructor `const`)
- Rich business methods (e.g., `isMeccan`, `bookmarkedVerses`)
- Equality based on identity fields
- No serialization logic (that belongs in `data/models`)

#### Other Entities
- `prayer_times_entity.dart` - Prayer time data with calculation metadata
- `quran_page_entity.dart` - Mushaf page representation (604 pages)
- `user_preferences_entity.dart` - User settings and preferences

### 2. Use Cases (Business Operations)
Each use case encapsulates a **single business operation** with validation and business rules.

#### Structure of a Use Case
```dart
class GetSurahUseCase {
  final QuranRepositoryInterface repository;
  
  const GetSurahUseCase(this.repository);
  
  Future<Result<Surah>> execute(int surahNumber) async {
    // 1. Input validation
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(
        message: 'Invalid surah number: $surahNumber. Must be between 1 and 114.'
      ));
    }
    
    // 2. Call repository
    final result = await repository.getSurah(surahNumber);
    
    // 3. Apply business rules
    if (result is Success<Surah>) {
      final surah = result.data;
      
      // Validate data integrity
      if (surah.verses.isEmpty) {
        return ResultError(QuranDataFailure(
          message: 'Surah $surahNumber has no verses'
        ));
      }
      
      // Verify verse count
      if (surah.verses.length != surah.numberOfAyahs) {
        return ResultError(QuranDataFailure(
          message: 'Verse count mismatch for Surah $surahNumber'
        ));
      }
      
      return Success(surah);
    }
    
    return result; // Pass through error
  }
}
```

**Use Case Responsibilities**:
1. **Input validation** - Ensure parameters meet business rules
2. **Orchestration** - Call repository/other use cases in correct order
3. **Business logic** - Apply domain rules (not data access rules)
4. **Error conversion** - Convert domain errors to appropriate Failures

#### Example: `usecases/manage_bookmarks_usecase.dart`
```dart
class ManageBookmarksUseCase {
  final QuranRepositoryInterface repository;
  
  const ManageBookmarksUseCase(this.repository);
  
  // Add bookmark with validation
  Future<Result<void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    // Validate input
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(message: 'Invalid surah number'));
    }
    
    // Check if already bookmarked
    final isBookmarked = await repository.isVerseBookmarked(surahNumber, verseNumber);
    if (isBookmarked is Success<bool> && isBookmarked.data) {
      return ResultError(ValidationFailure(message: 'Already bookmarked'));
    }
    
    // Add bookmark
    return await repository.addBookmark(surahNumber, verseNumber, note);
  }
  
  // Remove bookmark
  Future<Result<void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async {
    // Validation + business logic
    return await repository.removeBookmark(surahNumber, verseNumber);
  }
  
  // Toggle bookmark (convenience method)
  Future<Result<bool>> toggleBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    final isBookmarked = await repository.isVerseBookmarked(surahNumber, verseNumber);
    
    if (isBookmarked is Success<bool>) {
      if (isBookmarked.data) {
        await removeBookmark(surahNumber: surahNumber, verseNumber: verseNumber);
        return Success(false);
      } else {
        await addBookmark(surahNumber: surahNumber, verseNumber: verseNumber, note: note);
        return Success(true);
      }
    }
    
    return ResultError((isBookmarked as ResultError).failure);
  }
  
  // Get all bookmarks
  Future<Result<List<Bookmark>>> getAllBookmarks() async {
    return await repository.getAllBookmarks();
  }
  
  // Search bookmarks
  Future<Result<List<Bookmark>>> searchBookmarks(String query) async {
    if (query.isEmpty) {
      return ResultError(InvalidInputFailure(message: 'Query cannot be empty'));
    }
    return await repository.searchBookmarks(query);
  }
}
```

### 3. Repository Interfaces
Define **contracts** for data access. Implementations live in `data` layer.

#### `repositories/quran_repository_interface.dart`
```dart
abstract class QuranRepositoryInterface {
  // ===== SURAH OPERATIONS =====
  Future<Result<List<Surah>>> getAllSurahs();
  Future<Result<Surah>> getSurah(int surahNumber);
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber);
  Future<Result<List<Verse>>> getVerses(int surahNumber, {int? startVerse, int? endVerse});
  
  // ===== SEARCH OPERATIONS =====
  Future<Result<List<Verse>>> searchArabicText(String query);
  Future<Result<List<Verse>>> searchTranslation(String query, String translationKey);
  Future<Result<List<Surah>>> searchSurahs(String query);
  
  // ===== TRANSLATION OPERATIONS =====
  Future<Result<List<TranslationInfo>>> getAvailableTranslations();
  Future<Result<String>> getVerseTranslation(int surahNumber, int verseNumber, String translationKey);
  Future<Result<List<String>>> getSurahTranslations(int surahNumber, String translationKey);
  
  // ===== TAFSIR OPERATIONS =====
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs();
  Future<Result<String>> getVerseTafsir(int surahNumber, int verseNumber, String tafsirKey);
  
  // ===== AUDIO OPERATIONS =====
  Future<Result<List<ReciterInfo>>> getAvailableReciters();
  Future<Result<String>> getVerseAudioUrl(int surahNumber, int verseNumber, String reciterKey);
  Future<Result<String>> getSurahAudioUrl(int surahNumber, String reciterKey);
  
  // ===== BOOKMARK OPERATIONS =====
  Future<Result<void>> addBookmark(int surahNumber, int verseNumber, String? note);
  Future<Result<void>> removeBookmark(int surahNumber, int verseNumber);
  Future<Result<bool>> isVerseBookmarked(int surahNumber, int verseNumber);
  Future<Result<List<Bookmark>>> getAllBookmarks();
  Future<Result<List<Bookmark>>> searchBookmarks(String query);
  
  // ===== READING PROGRESS =====
  Future<Result<void>> saveReadingProgress(int surahNumber, int verseNumber);
  Future<Result<ReadingProgress?>> getLastReadingProgress();
}
```

**Interface Design Principles**:
1. **Return `Result<T>`** for all async operations (no exceptions)
2. **Named parameters** for clarity when multiple params (e.g., `{int? startVerse, int? endVerse}`)
3. **Grouped by feature** (comments for organization)
4. **No implementation details** - no mention of Hive, HTTP, or caching

## Result Pattern Usage

### Why Result<T>?
- Forces explicit error handling
- Type-safe error states
- No uncaught exceptions in business logic
- Clear separation between success and failure paths

### Pattern in Use Cases
```dart
Future<Result<T>> execute(...) async {
  // Validate
  if (invalid) {
    return ResultError(InvalidInputFailure(message: '...'));
  }
  
  // Call repository
  final result = await repository.getData();
  
  // Handle result
  if (result is Success<T>) {
    // Apply business logic
    final data = result.data;
    // ... transform/validate
    return Success(processedData);
  } else if (result is ResultError<T>) {
    // Log, transform, or pass through error
    return result;
  }
  
  // Should never reach here
  return ResultError(UnknownFailure(message: 'Unexpected state'));
}
```

### Error Handling Flow
```
Use Case → Repository → Data Source
   ↓           ↓             ↓
Validate    Cache/API    HTTP/Hive
   ↓           ↓             ↓
Result<T>   Result<T>   try/catch → Result<T>
```

## Common Patterns

### Pattern 1: Single-Item Retrieval
```dart
class GetSurahUseCase {
  Future<Result<Surah>> execute(int surahNumber) async {
    // Validate
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(message: '...'));
    }
    
    // Fetch
    final result = await repository.getSurah(surahNumber);
    
    // Validate result
    if (result is Success<Surah>) {
      // Additional business validation
      if (result.data.verses.isEmpty) {
        return ResultError(QuranDataFailure(message: 'No verses'));
      }
      return result;
    }
    
    return result;
  }
}
```

### Pattern 2: List Retrieval
```dart
class GetAllSurahsUseCase {
  Future<Result<List<Surah>>> execute() async {
    final result = await repository.getAllSurahs();
    
    if (result is Success<List<Surah>>) {
      final surahs = result.data;
      
      // Validate count
      if (surahs.length != 114) {
        return ResultError(QuranDataFailure(
          message: 'Expected 114 surahs, got ${surahs.length}'
        ));
      }
      
      // Sort by number
      surahs.sort((a, b) => a.number.compareTo(b.number));
      return Success(surahs);
    }
    
    return result;
  }
}
```

### Pattern 3: Multiple Operations (Orchestration)
```dart
class ManageBookmarksUseCase {
  Future<Result<bool>> toggleBookmark({...}) async {
    // 1. Check current state
    final isBookmarked = await repository.isVerseBookmarked(...);
    
    if (isBookmarked is Success<bool>) {
      // 2. Perform action based on state
      if (isBookmarked.data) {
        await removeBookmark(...);
        return Success(false);
      } else {
        await addBookmark(...);
        return Success(true);
      }
    }
    
    // 3. Handle error from check
    return ResultError((isBookmarked as ResultError).failure);
  }
}
```

### Pattern 4: Search/Filter Operations
```dart
class SearchQuranUseCase {
  Future<Result<List<Verse>>> execute(String query) async {
    // Validate
    if (query.trim().isEmpty) {
      return ResultError(InvalidInputFailure(message: 'Query cannot be empty'));
    }
    
    if (query.length < 3) {
      return ResultError(InvalidInputFailure(message: 'Query too short (min 3 chars)'));
    }
    
    // Search
    final result = await repository.searchArabicText(query);
    
    // Apply business logic (e.g., sorting, filtering)
    if (result is Success<List<Verse>>) {
      final verses = result.data;
      // Sort by relevance, surah number, etc.
      return Success(verses);
    }
    
    return result;
  }
}
```

## When to Create a New Use Case

**Create a new use case when**:
1. Operation has **business validation** beyond repository logic
2. Operation **orchestrates multiple repository calls**
3. Operation applies **domain-specific transformations**
4. You want to **encapsulate complex business rules**

**Don't create use case if**:
- Simple CRUD with no validation (though still recommended for consistency)
- Operation is purely UI logic (belongs in presentation)
- Operation is external integration (belongs in services)

## Testing Use Cases

Use cases are **highly testable** since they only depend on repository interfaces.

```dart
// test/domain/usecases/get_surah_usecase_test.dart
void main() {
  late GetSurahUseCase useCase;
  late MockQuranRepository mockRepository;
  
  setUp(() {
    mockRepository = MockQuranRepository();
    useCase = GetSurahUseCase(mockRepository);
  });
  
  group('GetSurahUseCase', () {
    test('should return Surah when surah number is valid', () async {
      // Arrange
      when(mockRepository.getSurah(1))
        .thenAnswer((_) async => Success(testSurah));
      
      // Act
      final result = await useCase.execute(1);
      
      // Assert
      expect(result, isA<Success<Surah>>());
      expect((result as Success<Surah>).data, equals(testSurah));
    });
    
    test('should return InvalidInputFailure when surah number is invalid', () async {
      // Act
      final result = await useCase.execute(115);
      
      // Assert
      expect(result, isA<ResultError<Surah>>());
      expect((result as ResultError<Surah>).failure, isA<InvalidInputFailure>());
    });
  });
}
```

## Adding New Features

### 1. Adding a New Entity
```dart
// domain/entities/my_entity.dart
class MyEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  
  const MyEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  
  // Business logic methods
  bool get isRecent => DateTime.now().difference(createdAt).inDays < 7;
}
```

### 2. Adding Repository Methods
```dart
// domain/repositories/quran_repository_interface.dart
abstract class QuranRepositoryInterface {
  // ... existing methods
  
  // New methods
  Future<Result<MyEntity>> getMyEntity(String id);
  Future<Result<List<MyEntity>>> getAllMyEntities();
}
```

### 3. Creating a New Use Case
```dart
// domain/usecases/get_my_entity_usecase.dart
class GetMyEntityUseCase {
  final QuranRepositoryInterface repository;
  
  const GetMyEntityUseCase(this.repository);
  
  Future<Result<MyEntity>> execute(String id) async {
    // Validation
    if (id.isEmpty) {
      return ResultError(InvalidInputFailure(message: 'ID cannot be empty'));
    }
    
    // Repository call
    return await repository.getMyEntity(id);
  }
}
```

### 4. Register in Dependency Injection
```dart
// core/utils/dependency_injection.dart
static late GetMyEntityUseCase _getMyEntityUseCase;

static Future<void> init() async {
  // ... existing init
  _getMyEntityUseCase = GetMyEntityUseCase(_quranRepository);
}

static GetMyEntityUseCase get getMyEntityUseCase => _getMyEntityUseCase;
```

## Common Mistakes to Avoid

### ❌ Don't: Import from outer layers
```dart
// domain/usecases/my_usecase.dart
import '../../data/models/cached_surah.dart'; // ❌ WRONG
import '../../presentation/providers/surah_provider.dart'; // ❌ WRONG
```

### ❌ Don't: Add framework dependencies
```dart
// domain/entities/surah_entity.dart
import 'package:hive/hive.dart'; // ❌ WRONG - belongs in data layer

@HiveType() // ❌ WRONG
class Surah { ... }
```

### ❌ Don't: Throw exceptions
```dart
// domain/usecases/get_surah_usecase.dart
Future<Result<Surah>> execute(int surahNumber) async {
  if (surahNumber < 1) {
    throw Exception('Invalid surah'); // ❌ WRONG - use Result
  }
}
```

### ✅ Do: Return Result
```dart
Future<Result<Surah>> execute(int surahNumber) async {
  if (surahNumber < 1) {
    return ResultError(InvalidInputFailure(message: 'Invalid surah')); // ✅ CORRECT
  }
}
```

### ❌ Don't: Add data access logic in use cases
```dart
class GetSurahUseCase {
  Future<Result<Surah>> execute(int surahNumber) async {
    // ❌ WRONG - HTTP call in use case
    final response = await http.get(Uri.parse('...'));
    // ...
  }
}
```

### ✅ Do: Delegate to repository
```dart
class GetSurahUseCase {
  Future<Result<Surah>> execute(int surahNumber) async {
    // ✅ CORRECT - delegate to repository
    return await repository.getSurah(surahNumber);
  }
}
```

---

**Related Documentation**:
- See `/AGENTS.md` for overall architecture
- See `lib/core/AGENTS.md` for Result pattern and error handling
- See `lib/data/AGENTS.md` for repository implementations
- See `lib/presentation/AGENTS.md` for using use cases in providers
