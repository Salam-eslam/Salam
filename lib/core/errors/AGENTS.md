# Core Errors - AGENTS.md

## Overview
This directory contains `failures.dart`, which defines all **Failure** classes used in the Result pattern. Failures represent domain/business errors and are returned in `ResultError<T>` instead of throwing exceptions.

## File: `failures.dart`

### Base Failure Class
```dart
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure({required this.message, this.code});
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}
```

**Key Characteristics**:
- Immutable (`const` constructor, `final` fields)
- Equality based on message and code
- Optional `code` for API error codes

## Failure Categories

### 1. Network Failures
Handle connectivity and HTTP-related errors.

```dart
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- No internet connection
- DNS resolution failure
- Socket timeout
- Network unreachable

**Example**:
```dart
// In data source
catch (SocketException e) {
  throw NetworkFailure(message: 'No internet connection');
}

// In repository
if (!await _hasInternetConnection) {
  return ResultError(NetworkFailure(message: 'No connection'));
}
```

---

```dart
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- HTTP 500 errors
- Invalid API response format
- API returns error status
- Unexpected server behavior

**Example**:
```dart
if (response.statusCode != 200) {
  throw ServerFailure(
    message: 'API error: ${response.reasonPhrase}',
    code: response.statusCode,
  );
}
```

---

```dart
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String message = 'Request timeout',
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- HTTP request exceeds timeout (30s)
- Server doesn't respond in time

**Example**:
```dart
try {
  final response = await client.get(url).timeout(Duration(seconds: 30));
} on TimeoutException {
  throw const TimeoutFailure();
}
```

### 2. Cache/Storage Failures
Handle local data persistence errors.

```dart
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Failed to read from Hive
- Cache data corrupted
- Cache key not found (when expected)

**Example**:
```dart
try {
  final cached = _box.get(key);
  if (cached == null) {
    throw CacheFailure(message: 'No cached data for key: $key');
  }
} catch (e) {
  throw CacheFailure(message: 'Failed to read cache: $e');
}
```

---

```dart
class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Failed to open Hive box
- Disk full
- Write permission denied
- SharedPreferences error

**Example**:
```dart
try {
  _box = await Hive.openBox<T>('my_box');
} catch (e) {
  throw StorageFailure(message: 'Failed to initialize storage: $e');
}
```

### 3. Business Logic Failures
Handle domain-specific errors.

```dart
class InvalidInputFailure extends Failure {
  const InvalidInputFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- User input validation fails
- Parameter out of valid range
- Required field missing

**Example**:
```dart
// In use case
if (surahNumber < 1 || surahNumber > 114) {
  return ResultError(InvalidInputFailure(
    message: 'Invalid surah number: $surahNumber. Must be 1-114.',
  ));
}

if (query.trim().isEmpty) {
  return ResultError(InvalidInputFailure(
    message: 'Search query cannot be empty',
  ));
}
```

---

```dart
class QuranDataFailure extends Failure {
  const QuranDataFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Quran data integrity issue
- Verse count mismatch
- Invalid Quran structure

**Example**:
```dart
if (surah.verses.isEmpty) {
  return ResultError(QuranDataFailure(
    message: 'Surah $surahNumber has no verses',
  ));
}

if (surah.verses.length != surah.numberOfAyahs) {
  return ResultError(QuranDataFailure(
    message: 'Verse count mismatch: expected ${surah.numberOfAyahs}, got ${surah.verses.length}',
  ));
}
```

---

```dart
class BookmarkFailure extends Failure {
  const BookmarkFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Failed to save bookmark
- Bookmark already exists (duplicate)
- Bookmark not found when removing

**Example**:
```dart
if (await _isBookmarked(surah, verse)) {
  return ResultError(BookmarkFailure(
    message: 'Verse $surah:$verse is already bookmarked',
  ));
}
```

---

```dart
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Business rule validation fails
- Complex validation logic
- Multiple field validation

**Example**:
```dart
if (password.length < 8) {
  return ResultError(ValidationFailure(
    message: 'Password must be at least 8 characters',
  ));
}
```

### 4. Resource Failures
Handle missing or unavailable resources.

```dart
class SurahNotFoundFailure extends Failure {
  final int surahNumber;
  
  const SurahNotFoundFailure({
    required this.surahNumber,
  }) : super(message: 'Surah $surahNumber not found');
}
```

**When to Use**:
- API returns 404 for surah
- Requested surah doesn't exist

**Example**:
```dart
if (response.statusCode == 404) {
  throw SurahNotFoundFailure(surahNumber: surahNumber);
}
```

---

```dart
class VerseNotFoundFailure extends Failure {
  final int surahNumber;
  final int verseNumber;
  
  const VerseNotFoundFailure({
    required this.surahNumber,
    required this.verseNumber,
  }) : super(message: 'Verse $surahNumber:$verseNumber not found');
}
```

**When to Use**:
- API returns 404 for verse
- Verse number exceeds surah length

**Example**:
```dart
if (verseNumber > surah.numberOfAyahs) {
  throw VerseNotFoundFailure(
    surahNumber: surahNumber,
    verseNumber: verseNumber,
  );
}
```

---

```dart
class AudioNotFoundFailure extends Failure {
  const AudioNotFoundFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Audio file not available on CDN
- Reciter doesn't have this surah/verse
- Audio URL returns 404

### 5. Permission/Auth Failures
Handle access control errors.

```dart
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Location permission denied (prayer times)
- Notification permission denied
- Storage permission denied

**Example**:
```dart
if (await Permission.location.isDenied) {
  return ResultError(PermissionDeniedFailure(
    message: 'Location permission required for prayer times',
  ));
}
```

### 6. Generic Failures

```dart
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'An unknown error occurred',
    int? code,
  }) : super(message: message, code: code);
}
```

**When to Use**:
- Catch-all for unexpected errors
- Should be rare if error handling is comprehensive

**Example**:
```dart
catch (e) {
  if (e is Failure) rethrow;
  throw UnknownFailure(message: 'Unexpected error: $e');
}
```

## Usage Patterns

### Pattern 1: Data Source (Throw Failures)
```dart
// In remote_datasource.dart
Future<Map<String, dynamic>> fetchData() async {
  try {
    final response = await client.get(url).timeout(Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else if (response.statusCode == 404) {
      throw SurahNotFoundFailure(surahNumber: surahNumber);
    } else {
      throw ServerFailure(
        message: 'API error: ${response.reasonPhrase}',
        code: response.statusCode,
      );
    }
  } on TimeoutException {
    throw const TimeoutFailure();
  } on SocketException {
    throw NetworkFailure(message: 'No internet connection');
  } catch (e) {
    if (e is Failure) rethrow;
    throw ServerFailure(message: 'Unexpected: $e');
  }
}
```

### Pattern 2: Repository (Catch and Convert to Result)
```dart
// In repository.dart
@override
Future<Result<Surah>> getSurah(int surahNumber) async {
  try {
    final data = await dataSource.fetchSurah(surahNumber);
    return Success(data);
  } on NetworkFailure catch (f) {
    return ResultError(f);
  } on ServerFailure catch (f) {
    return ResultError(f);
  } on SurahNotFoundFailure catch (f) {
    return ResultError(f);
  } catch (e) {
    return ResultError(ServerFailure(message: 'Unexpected: $e'));
  }
}
```

### Pattern 3: Use Case (Validate and Return Result)
```dart
// In use_case.dart
Future<Result<Surah>> execute(int surahNumber) async {
  // Validation
  if (surahNumber < 1 || surahNumber > 114) {
    return ResultError(InvalidInputFailure(
      message: 'Invalid surah number: $surahNumber',
    ));
  }
  
  // Call repository (already returns Result)
  final result = await repository.getSurah(surahNumber);
  
  // Additional business validation
  if (result is Success<Surah>) {
    if (result.data.verses.isEmpty) {
      return ResultError(QuranDataFailure(
        message: 'Surah has no verses',
      ));
    }
  }
  
  return result;
}
```

### Pattern 4: Provider (Handle Result in UI)
```dart
// In provider.dart
Future<void> loadSurah(int surahNumber) async {
  _isLoading = true;
  notifyListeners();
  
  final result = await useCase.execute(surahNumber);
  
  if (result is Success<Surah>) {
    _surah = result.data;
    _error = null;
  } else if (result is ResultError<Surah>) {
    _error = result.failure.message;
    
    // Handle specific failure types
    if (result.failure is NetworkFailure) {
      _error = 'No internet connection. Showing cached data.';
    } else if (result.failure is SurahNotFoundFailure) {
      _error = 'This surah could not be found.';
    }
  }
  
  _isLoading = false;
  notifyListeners();
}
```

## Adding New Failure Types

### Step 1: Define Failure Class
```dart
// In failures.dart
class MyNewFailure extends Failure {
  const MyNewFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
```

### Step 2: Throw in Data Source
```dart
if (someCondition) {
  throw MyNewFailure(message: 'Something went wrong');
}
```

### Step 3: Catch in Repository
```dart
} on MyNewFailure catch (f) {
  return ResultError(f);
}
```

### Step 4: Handle in Provider (Optional)
```dart
if (result.failure is MyNewFailure) {
  // Special handling
}
```

## Best Practices

### ✅ Do: Provide Meaningful Messages
```dart
return ResultError(InvalidInputFailure(
  message: 'Surah number must be between 1 and 114, got: $surahNumber',
));
```

### ✅ Do: Include Context
```dart
throw ServerFailure(
  message: 'Failed to fetch surah $surahNumber: ${response.reasonPhrase}',
  code: response.statusCode,
);
```

### ✅ Do: Use Specific Failure Types
```dart
if (response.statusCode == 404) {
  throw SurahNotFoundFailure(surahNumber: surahNumber);
} else {
  throw ServerFailure(message: '...', code: response.statusCode);
}
```

### ❌ Don't: Use Generic Messages
```dart
return ResultError(Failure(message: 'Error')); // Too vague
```

### ❌ Don't: Throw Exceptions in Use Cases
```dart
// WRONG
throw Exception('Invalid input');

// CORRECT
return ResultError(InvalidInputFailure(message: 'Invalid input'));
```

### ❌ Don't: Swallow Errors
```dart
// WRONG
try {
  await doSomething();
} catch (e) {
  // Silent failure
}

// CORRECT
try {
  await doSomething();
} catch (e) {
  return ResultError(ServerFailure(message: '$e'));
}
```

## Testing Failures

```dart
test('should return InvalidInputFailure for invalid surah number', () async {
  // Arrange
  final useCase = GetSurahUseCase(mockRepository);
  
  // Act
  final result = await useCase.execute(115);
  
  // Assert
  expect(result, isA<ResultError<Surah>>());
  expect((result as ResultError<Surah>).failure, isA<InvalidInputFailure>());
  expect(result.failure.message, contains('Invalid surah number'));
});
```

---

**Related Documentation**:
- See `lib/core/AGENTS.md` for Result pattern overview
- See `lib/domain/AGENTS.md` for use case error handling
- See `lib/data/AGENTS.md` for repository error handling
