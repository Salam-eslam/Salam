# Domain Use Cases - AGENTS.md

## Overview
Use cases encapsulate **single-purpose business logic** operations. They orchestrate domain entities and repository interfaces to fulfill specific user intentions. Each use case represents one "action" in the system.

**Key Principles**:
- One use case = One business operation
- Depend only on repository interfaces (not implementations)
- Return `Result<T>` for error handling
- Validate inputs and enforce business rules
- Pure business logic (no UI, no framework dependencies)

## Files

### 1. `get_surah_usecase.dart`
Retrieves Surah data with validation and integrity checks.

**Core Structure**:
```dart
class GetSurahUseCase {
  final QuranRepositoryInterface repository;
  
  const GetSurahUseCase(this.repository);
  
  Future<Result<Surah>> execute(int surahNumber) async { /* ... */ }
  Future<Result<List<Surah>>> executeMultiple(List<int> surahNumbers) async { /* ... */ }
  Future<Result<List<Surah>>> executeRange(int start, int end) async { /* ... */ }
  Future<Result<Surah>> getSurahWithTranslation(int surahNumber, String translationKey) async { /* ... */ }
}
```

**Business Logic Flow**:

**1. Single Surah Retrieval**:
```dart
Future<Result<Surah>> execute(int surahNumber) async {
  // Step 1: Validate input
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(
      InvalidInputFailure(
        message: 'Invalid surah number: $surahNumber. Must be between 1 and 114.',
      ),
    );
  }

  // Step 2: Fetch from repository
  final result = await repository.getSurah(surahNumber);

  // Step 3: Validate data integrity
  if (result is Success<Surah>) {
    final surah = result.data;

    // Check verses exist
    if (surah.verses.isEmpty) {
      return ResultError(
        QuranDataFailure(message: 'Surah $surahNumber has no verses'),
      );
    }

    // Verify verse count matches
    if (surah.verses.length != surah.numberOfAyahs) {
      return ResultError(
        QuranDataFailure(
          message: 'Verse count mismatch for Surah $surahNumber: '
              'expected ${surah.numberOfAyahs}, got ${surah.verses.length}',
        ),
      );
    }

    return Success(surah);
  }

  return result; // Pass through error
}
```

**2. Multiple Surahs Retrieval**:
```dart
Future<Result<List<Surah>>> executeMultiple(List<int> surahNumbers) async {
  // Validate input list
  if (surahNumbers.isEmpty) {
    return ResultError(
      InvalidInputFailure(message: 'Surah numbers list cannot be empty'),
    );
  }

  // Check for invalid numbers
  final invalidNumbers = surahNumbers.where((num) => num < 1 || num > 114).toList();
  if (invalidNumbers.isNotEmpty) {
    return ResultError(
      InvalidInputFailure(
        message: 'Invalid surah numbers: $invalidNumbers. Must be between 1 and 114.',
      ),
    );
  }

  // Fetch all surahs
  final surahs = <Surah>[];
  for (final surahNumber in surahNumbers) {
    final result = await execute(surahNumber);
    
    if (result is Success<Surah>) {
      surahs.add(result.data);
    } else if (result is ResultError<Surah>) {
      // Return first error encountered
      return ResultError(result.failure);
    }
  }

  return Success(surahs);
}
```

**3. Range Retrieval**:
```dart
Future<Result<List<Surah>>> executeRange(int start, int end) async {
  // Validate range
  if (start < 1 || end > 114 || start > end) {
    return ResultError(
      InvalidInputFailure(
        message: 'Invalid range: $start-$end. Must be 1-114 and start ≤ end.',
      ),
    );
  }

  // Convert range to list
  final surahNumbers = List.generate(end - start + 1, (i) => start + i);
  
  return await executeMultiple(surahNumbers);
}
```

**4. Surah with Translation**:
```dart
Future<Result<Surah>> getSurahWithTranslation(
  int surahNumber,
  String translationKey,
) async {
  // Get base surah
  final surahResult = await execute(surahNumber);
  
  if (surahResult is ResultError<Surah>) {
    return surahResult;
  }
  
  final surah = (surahResult as Success<Surah>).data;
  
  // Get translations
  final translationsResult = await repository.getSurahTranslations(
    surahNumber,
    translationKey,
  );
  
  if (translationsResult is ResultError<List<String>>) {
    // Translation failed - return surah without translation
    return Success(surah);
  }
  
  final translations = (translationsResult as Success<List<String>>).data;
  
  // Merge translation into verses
  final updatedVerses = surah.verses.asMap().entries.map((entry) {
    final index = entry.key;
    final verse = entry.value;
    final translation = index < translations.length ? translations[index] : null;
    
    return verse.copyWith(translation: translation);
  }).toList();
  
  return Success(surah.copyWith(verses: updatedVerses));
}
```

**Usage in Provider**:
```dart
class SurahProvider extends ChangeNotifier {
  final GetSurahUseCase _getSurahUseCase;
  
  Future<bool> loadSurah(int surahNumber, {String? translationKey}) async {
    _setLoading(true);
    
    final result = translationKey != null
        ? await _getSurahUseCase.getSurahWithTranslation(surahNumber, translationKey)
        : await _getSurahUseCase.execute(surahNumber);
    
    if (result is Success<Surah>) {
      _currentSurah = result.data;
      _setLoading(false);
      return true;
    } else if (result is ResultError<Surah>) {
      _setError(result.failure.message);
      _setLoading(false);
      return false;
    }
    
    return false;
  }
}
```

---

### 2. `manage_bookmarks_usecase.dart`
Manages verse bookmarks with validation and duplicate checking.

**Core Structure**:
```dart
class ManageBookmarksUseCase {
  final QuranRepositoryInterface repository;
  
  const ManageBookmarksUseCase(this.repository);
  
  Future<Result<void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async { /* ... */ }
  
  Future<Result<void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async { /* ... */ }
  
  Future<Result<List<Bookmark>>> getAllBookmarks() async { /* ... */ }
  
  Future<Result<void>> updateBookmarkNote({
    required int surahNumber,
    required int verseNumber,
    required String note,
  }) async { /* ... */ }
  
  Future<Result<bool>> isVerseBookmarked({
    required int surahNumber,
    required int verseNumber,
  }) async { /* ... */ }
  
  Future<Result<void>> clearAllBookmarks() async { /* ... */ }
}
```

**Business Logic Flow**:

**1. Add Bookmark**:
```dart
Future<Result<void>> addBookmark({
  required int surahNumber,
  required int verseNumber,
  String? note,
}) async {
  // Step 1: Validate surah number
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid surah number: $surahNumber'),
    );
  }

  // Step 2: Validate verse number
  if (verseNumber < 1) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid verse number: $verseNumber'),
    );
  }

  // Step 3: Check for duplicates
  final isBookmarkedResult = await repository.isVerseBookmarked(
    surahNumber,
    verseNumber,
  );

  if (isBookmarkedResult is Success<bool> && isBookmarkedResult.data) {
    return ResultError(
      ValidationFailure(
        message: 'Verse $surahNumber:$verseNumber is already bookmarked',
      ),
    );
  }

  // Step 4: Add bookmark
  return await repository.addBookmark(surahNumber, verseNumber, note);
}
```

**2. Remove Bookmark**:
```dart
Future<Result<void>> removeBookmark({
  required int surahNumber,
  required int verseNumber,
}) async {
  // Validate input
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid surah number: $surahNumber'),
    );
  }

  if (verseNumber < 1) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid verse number: $verseNumber'),
    );
  }

  // Check if bookmarked first
  final isBookmarkedResult = await repository.isVerseBookmarked(
    surahNumber,
    verseNumber,
  );

  if (isBookmarkedResult is Success<bool> && !isBookmarkedResult.data) {
    return ResultError(
      ValidationFailure(
        message: 'Verse $surahNumber:$verseNumber is not bookmarked',
      ),
    );
  }

  // Remove bookmark
  return await repository.removeBookmark(surahNumber, verseNumber);
}
```

**3. Get All Bookmarks**:
```dart
Future<Result<List<Bookmark>>> getAllBookmarks() async {
  final result = await repository.getAllBookmarks();

  if (result is Success<List<Bookmark>>) {
    // Sort by most recent first
    final bookmarks = result.data;
    bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(bookmarks);
  }

  return result;
}
```

**4. Update Bookmark Note**:
```dart
Future<Result<void>> updateBookmarkNote({
  required int surahNumber,
  required int verseNumber,
  required String note,
}) async {
  // Validate input
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid surah number: $surahNumber'),
    );
  }

  if (verseNumber < 1) {
    return ResultError(
      InvalidInputFailure(message: 'Invalid verse number: $verseNumber'),
    );
  }

  if (note.isEmpty) {
    return ResultError(
      InvalidInputFailure(message: 'Note cannot be empty'),
    );
  }

  // Check if bookmarked
  final isBookmarkedResult = await repository.isVerseBookmarked(
    surahNumber,
    verseNumber,
  );

  if (isBookmarkedResult is Success<bool> && !isBookmarkedResult.data) {
    return ResultError(
      ValidationFailure(
        message: 'Verse $surahNumber:$verseNumber is not bookmarked',
      ),
    );
  }

  // Update note
  return await repository.updateBookmarkNote(surahNumber, verseNumber, note);
}
```

**5. Clear All Bookmarks**:
```dart
Future<Result<void>> clearAllBookmarks() async {
  // Get current bookmarks
  final bookmarksResult = await repository.getAllBookmarks();

  if (bookmarksResult is Success<List<Bookmark>>) {
    // Warn if many bookmarks
    if (bookmarksResult.data.length > 50) {
      // Could return confirmation required error
      // Or just proceed
    }
  }

  return await repository.clearAllBookmarks();
}
```

**Usage in Provider**:
```dart
class BookmarksProvider extends ChangeNotifier {
  final ManageBookmarksUseCase _manageBookmarksUseCase;
  
  Future<bool> addBookmark(int surahNumber, int verseNumber, {String? note}) async {
    final result = await _manageBookmarksUseCase.addBookmark(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      note: note,
    );
    
    if (result is Success<void>) {
      await _refreshBookmarks();
      notifyListeners();
      return true;
    } else if (result is ResultError<void>) {
      _setError(result.failure.message);
      return false;
    }
    
    return false;
  }
  
  Future<void> _refreshBookmarks() async {
    final result = await _manageBookmarksUseCase.getAllBookmarks();
    if (result is Success<List<Bookmark>>) {
      _bookmarks = result.data;
    }
  }
}
```

---

## Use Case Design Patterns

### Pattern 1: Single Responsibility
Each use case does ONE thing:
```dart
// ✅ Correct - focused use case
class GetSurahUseCase {
  Future<Result<Surah>> execute(int surahNumber) { /* ... */ }
}

// ❌ Wrong - too many responsibilities
class QuranUseCase {
  Future<Result<Surah>> getSurah() { /* ... */ }
  Future<Result<void>> addBookmark() { /* ... */ }
  Future<Result<List<Prayer>>> getPrayerTimes() { /* ... */ }
}
```

### Pattern 2: Input Validation First
Always validate before calling repository:
```dart
Future<Result<T>> execute(Input input) async {
  // 1. Validate
  if (invalid) return ResultError(InvalidInputFailure(...));
  
  // 2. Call repository
  final result = await repository.operation();
  
  // 3. Apply business rules
  if (result is Success) { /* ... */ }
  
  return result;
}
```

### Pattern 3: Repository Interface Dependency
Depend on interface, not implementation:
```dart
// ✅ Correct
class GetSurahUseCase {
  final QuranRepositoryInterface repository;
  const GetSurahUseCase(this.repository);
}

// ❌ Wrong
class GetSurahUseCase {
  final QuranRepository repository; // Concrete implementation
}
```

### Pattern 4: Result Pattern Propagation
Handle results explicitly:
```dart
final result = await repository.getData();

if (result is Success<T>) {
  // Success path
  return Success(processedData);
} else if (result is ResultError<T>) {
  // Error path
  return ResultError(result.failure);
}
```

### Pattern 5: Composing Use Cases
Use cases can call other use cases:
```dart
class GetSurahWithDetailsUseCase {
  final GetSurahUseCase _getSurahUseCase;
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  
  Future<Result<SurahDetails>> execute(int surahNumber) async {
    final surahResult = await _getSurahUseCase.execute(surahNumber);
    if (surahResult is ResultError) return ResultError(surahResult.failure);
    
    final prayerResult = await _getPrayerTimesUseCase.execute();
    // ... compose results
  }
}
```

---

## Testing Use Cases

### Test Input Validation
```dart
test('should return error for invalid surah number', () async {
  final useCase = GetSurahUseCase(mockRepository);
  
  final result = await useCase.execute(0);
  
  expect(result, isA<ResultError<Surah>>());
  expect((result as ResultError).failure, isA<InvalidInputFailure>());
});
```

### Test Business Logic
```dart
test('should validate verse count matches', () async {
  when(mockRepository.getSurah(1)).thenAnswer(
    (_) async => Success(Surah(
      numberOfAyahs: 7,
      verses: [/* only 5 verses */],
    )),
  );
  
  final useCase = GetSurahUseCase(mockRepository);
  final result = await useCase.execute(1);
  
  expect(result, isA<ResultError<Surah>>());
  expect((result as ResultError).failure, isA<QuranDataFailure>());
});
```

### Test Repository Interaction
```dart
test('should call repository with correct parameters', () async {
  when(mockRepository.getSurah(any)).thenAnswer(
    (_) async => Success(validSurah),
  );
  
  final useCase = GetSurahUseCase(mockRepository);
  await useCase.execute(1);
  
  verify(mockRepository.getSurah(1)).called(1);
});
```

---

## Common Pitfalls

### ❌ Pitfall 1: No Input Validation
```dart
// ❌ WRONG - no validation
Future<Result<Surah>> execute(int surahNumber) async {
  return await repository.getSurah(surahNumber); // What if invalid?
}

// ✅ CORRECT
Future<Result<Surah>> execute(int surahNumber) async {
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(InvalidInputFailure(...));
  }
  return await repository.getSurah(surahNumber);
}
```

### ❌ Pitfall 2: Direct Exception Throwing
```dart
// ❌ WRONG - breaks Result pattern
Future<Result<Surah>> execute(int surahNumber) async {
  if (invalid) throw Exception('Invalid');
  // ...
}

// ✅ CORRECT
Future<Result<Surah>> execute(int surahNumber) async {
  if (invalid) return ResultError(InvalidInputFailure(...));
  // ...
}
```

### ❌ Pitfall 3: UI Logic in Use Case
```dart
// ❌ WRONG - UI concerns
Future<Result<void>> addBookmark(int surahNumber, int verseNumber) async {
  // Show loading spinner - NO!
  final result = await repository.addBookmark(...);
  // Show success toast - NO!
  return result;
}

// ✅ CORRECT - pure business logic
Future<Result<void>> addBookmark(int surahNumber, int verseNumber) async {
  if (invalid) return ResultError(...);
  return await repository.addBookmark(...);
}
```

### ❌ Pitfall 4: Ignoring Result Type
```dart
// ❌ WRONG - assuming success
Future<void> execute() async {
  final result = await repository.getData();
  final data = result.data; // Compile error if ResultError!
}

// ✅ CORRECT - handle both cases
Future<Result<T>> execute() async {
  final result = await repository.getData();
  if (result is Success<T>) {
    return Success(result.data);
  } else {
    return ResultError((result as ResultError).failure);
  }
}
```

---

**Related Documentation**:
- See `lib/domain/AGENTS.md` for domain layer overview
- See `lib/domain/entities/AGENTS.md` for entity structure
- See `lib/domain/repositories/AGENTS.md` for repository interfaces
- See `lib/presentation/providers/AGENTS.md` for use case usage in providers
