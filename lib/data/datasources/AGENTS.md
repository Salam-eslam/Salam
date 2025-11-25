# Data Sources - AGENTS.md

## Overview
Data sources are the **entry points** for external data in the data layer. They directly interact with APIs, static data, or other external sources. Data sources do NOT handle caching or error conversion to `Result<T>` - that's the repository's job.

**Key Principles**:
- Direct interaction with external data (HTTP, static files, etc.)
- Throw `Failure` exceptions (repository converts to `Result`)
- No business logic - just data fetching
- Return raw data (Maps/Lists) or domain entities

## Files

### 1. `quran_remote_datasource.dart`
HTTP client for Quran API (api.alquran.cloud/v1).

**Purpose**: Fetch Quran data from remote API.

**Core Structure**:
```dart
class QuranRemoteDataSource {
  final http.Client client;
  
  const QuranRemoteDataSource({required this.client});
  
  // Surah operations
  Future<List<Map<String, dynamic>>> getAllSurahs() async { /* ... */ }
  Future<Map<String, dynamic>> getSurah(int surahNumber) async { /* ... */ }
  Future<Map<String, dynamic>> getVerse(int surahNumber, int verseNumber) async { /* ... */ }
  
  // Translation operations
  Future<List<Map<String, dynamic>>> getAvailableTranslations() async { /* ... */ }
  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber, String translationKey) async { /* ... */ }
  
  // Search operations
  Future<List<Map<String, dynamic>>> searchVerses(String query) async { /* ... */ }
  
  // Audio operations
  Future<String> getAudioUrl(int surahNumber, String reciterKey) async { /* ... */ }
}
```

**API Endpoints Used**:
```dart
// Base URL from AppConstants
static const baseUrl = 'https://api.alquran.cloud/v1';

// Endpoints
GET /surah                    // All surahs metadata
GET /surah/{surahNumber}      // Specific surah with verses
GET /ayah/{ayahNumber}        // Specific verse by global number
GET /search/{keyword}         // Search verses
GET /edition                  // Available translations/editions
GET /surah/{surah}/{edition}  // Surah with specific translation
```

**Implementation Pattern**:

**Standard GET Request**:
```dart
Future<Map<String, dynamic>> getSurah(int surahNumber) async {
  try {
    // 1. Make HTTP request with timeout
    final response = await client.get(
      Uri.parse('${AppConstants.quranApiBaseUrl}/surah/$surahNumber'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    // 2. Check status code
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // 3. Validate response structure
      if (data['status'] == 'OK' && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ServerFailure(
          message: 'Invalid API response format',
          code: response.statusCode,
        );
      }
    } else {
      throw ServerFailure(
        message: 'Failed to fetch surah: ${response.reasonPhrase}',
        code: response.statusCode,
      );
    }
  } on TimeoutException {
    throw const TimeoutFailure();
  } on http.ClientException catch (e) {
    throw NetworkFailure(message: 'Network error: ${e.message}');
  } catch (e) {
    if (e is Failure) rethrow;
    throw ServerFailure(message: 'Unexpected error: $e');
  }
}
```

**Error Handling Strategy**:
```dart
try {
  // API call
} on TimeoutException {
  throw const TimeoutFailure();              // Request timeout
} on http.ClientException catch (e) {
  throw NetworkFailure(message: e.message);  // Network error
} on FormatException {
  throw const ServerFailure(                 // JSON parse error
    message: 'Invalid response format',
  );
} catch (e) {
  if (e is Failure) rethrow;                 // Already a Failure
  throw ServerFailure(message: '$e');        // Unknown error
}
```

**Get All Surahs** (Metadata Only):
```dart
Future<List<Map<String, dynamic>>> getAllSurahs() async {
  try {
    final response = await client.get(
      Uri.parse('${AppConstants.quranApiBaseUrl}/surah'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['data'] != null) {
        // Returns list of 114 surahs with basic info
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw ServerFailure(
          message: 'Invalid API response format',
          code: response.statusCode,
        );
      }
    } else {
      throw ServerFailure(
        message: 'Failed to fetch surahs: ${response.reasonPhrase}',
        code: response.statusCode,
      );
    }
  } on TimeoutException {
    throw const TimeoutFailure();
  } on http.ClientException catch (e) {
    throw NetworkFailure(message: 'Network error: ${e.message}');
  } catch (e) {
    if (e is Failure) rethrow;
    throw ServerFailure(message: 'Unexpected error: $e');
  }
}
```

**Response Format** (from API):
```json
{
  "status": "OK",
  "data": [
    {
      "number": 1,
      "name": "سُورَةُ ٱلْفَاتِحَةِ",
      "englishName": "Al-Fatihah",
      "englishNameTranslation": "The Opening",
      "revelationType": "Meccan",
      "numberOfAyahs": 7
    },
    // ... 113 more surahs
  ]
}
```

**Get Surah with Translation**:
```dart
Future<Map<String, dynamic>> getSurahWithTranslation(
  int surahNumber,
  String translationKey, // e.g., 'en.sahih'
) async {
  try {
    final response = await client.get(
      Uri.parse(
        '${AppConstants.quranApiBaseUrl}/surah/$surahNumber/$translationKey',
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw ServerFailure(
          message: 'Invalid API response format',
          code: response.statusCode,
        );
      }
    } else {
      throw ServerFailure(
        message: 'Failed to fetch translation: ${response.reasonPhrase}',
        code: response.statusCode,
      );
    }
  } on TimeoutException {
    throw const TimeoutFailure();
  } on http.ClientException catch (e) {
    throw NetworkFailure(message: 'Network error: ${e.message}');
  } catch (e) {
    if (e is Failure) rethrow;
    throw ServerFailure(message: 'Unexpected error: $e');
  }
}
```

**Search Verses**:
```dart
Future<List<Map<String, dynamic>>> searchVerses(String query) async {
  if (query.isEmpty) {
    throw const InvalidInputFailure(message: 'Search query cannot be empty');
  }

  try {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await client.get(
      Uri.parse('${AppConstants.quranApiBaseUrl}/search/$encodedQuery/all/en'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['data'] != null) {
        final matches = data['data']['matches'] as List;
        return List<Map<String, dynamic>>.from(matches);
      } else {
        throw ServerFailure(
          message: 'Invalid API response format',
          code: response.statusCode,
        );
      }
    } else {
      throw ServerFailure(
        message: 'Search failed: ${response.reasonPhrase}',
        code: response.statusCode,
      );
    }
  } on TimeoutException {
    throw const TimeoutFailure();
  } on http.ClientException catch (e) {
    throw NetworkFailure(message: 'Network error: ${e.message}');
  } catch (e) {
    if (e is Failure) rethrow;
    throw ServerFailure(message: 'Unexpected error: $e');
  }
}
```

**Usage in Repository**:
```dart
class QuranRepository implements QuranRepositoryInterface {
  final QuranRemoteDataSource remoteDataSource;
  
  @override
  Future<Result<Surah>> getSurah(int surahNumber) async {
    try {
      // Call data source (may throw Failure)
      final data = await remoteDataSource.getSurah(surahNumber);
      
      // Convert to domain entity
      final surah = Surah.fromJson(data);
      
      // Cache it
      await _cacheSurah(surah);
      
      return Success(surah);
    } on Failure catch (failure) {
      // Convert Failure exception to Result
      return ResultError(failure);
    } catch (e) {
      return ResultError(ServerFailure(message: '$e'));
    }
  }
}
```

**Testing Data Source**:
```dart
test('should return surah data from API', () async {
  // Arrange
  final mockClient = MockClient();
  final dataSource = QuranRemoteDataSource(client: mockClient);
  
  when(mockClient.get(any, headers: anyNamed('headers')))
    .thenAnswer((_) async => http.Response(
      '{"status":"OK","data":{"number":1,"name":"الفاتحة"}}',
      200,
    ));
  
  // Act
  final result = await dataSource.getSurah(1);
  
  // Assert
  expect(result, isA<Map<String, dynamic>>());
  expect(result['number'], 1);
});

test('should throw TimeoutFailure on timeout', () async {
  when(mockClient.get(any, headers: anyNamed('headers')))
    .thenThrow(TimeoutException('Timeout'));
  
  expect(
    () => dataSource.getSurah(1),
    throwsA(isA<TimeoutFailure>()),
  );
});
```

---

### 2. `quran_page_data.dart`
Static data mapping for Mushaf page structure (604 pages).

**Purpose**: Provide page-to-verse mapping for Mushaf-style reading.

**Core Structure**:
```dart
class QuranPageData {
  static const int totalPages = 604;
  
  // Maps page number to [surahNumber, startingAyahNumber]
  static const Map<int, List<int>> pageStartMapping = {
    1: [1, 1],      // Page 1: Al-Fatihah 1
    2: [2, 1],      // Page 2: Al-Baqarah 1
    3: [2, 6],      // Page 3: Al-Baqarah 6
    // ... 604 pages total
    604: [114, 1],  // Page 604: An-Nas 1
  };
  
  // Helper methods
  static List<int>? getPageStart(int pageNumber) {
    return pageStartMapping[pageNumber];
  }
  
  static int? getSurahForPage(int pageNumber) {
    return pageStartMapping[pageNumber]?[0];
  }
  
  static int? getVerseForPage(int pageNumber) {
    return pageStartMapping[pageNumber]?[1];
  }
  
  static int? getPageForVerse(int surahNumber, int verseNumber) {
    // Iterate through mapping to find page
    for (final entry in pageStartMapping.entries) {
      final pageNum = entry.key;
      final surah = entry.value[0];
      final verse = entry.value[1];
      
      if (surah == surahNumber && verse <= verseNumber) {
        // Check if next page starts after this verse
        final nextPage = pageStartMapping[pageNum + 1];
        if (nextPage == null || 
            nextPage[0] > surahNumber ||
            (nextPage[0] == surahNumber && nextPage[1] > verseNumber)) {
          return pageNum;
        }
      }
    }
    return null;
  }
}
```

**Why Static Data?**
- Mushaf page structure is **standardized** (Madani Mushaf)
- Never changes (unlike API data that might update)
- Faster than API calls
- Works offline
- No caching needed

**Data Format**:
```dart
// Page 1: Entire Al-Fatihah (surah 1, verses 1-7)
1: [1, 1],

// Page 2: Start of Al-Baqarah
2: [2, 1],

// Page 3: Al-Baqarah continues from verse 6
3: [2, 6],

// Page 50: Middle of Al-Baqarah (verse 142)
50: [2, 142],

// Pages can span multiple surahs
// Page 187: Ends surah 9, starts surah 10
187: [10, 1],

// Last page
604: [114, 1], // An-Nas (all 6 verses fit on one page)
```

**Usage in Repository**:
```dart
@override
Future<Result<QuranPage>> getPage(int pageNumber) async {
  if (pageNumber < 1 || pageNumber > QuranPageData.totalPages) {
    return ResultError(
      InvalidInputFailure(
        message: 'Invalid page number: $pageNumber. Must be 1-604.',
      ),
    );
  }

  try {
    // Get page start
    final pageStart = QuranPageData.getPageStart(pageNumber);
    if (pageStart == null) {
      return ResultError(
        QuranDataFailure(message: 'Page $pageNumber not found in mapping'),
      );
    }

    final startSurah = pageStart[0];
    final startVerse = pageStart[1];

    // Get next page start to determine end
    final nextPageStart = QuranPageData.getPageStart(pageNumber + 1);

    // Fetch all verses for this page from API
    // ... fetch logic using start/end positions

    return Success(quranPage);
  } on Failure catch (failure) {
    return ResultError(failure);
  }
}

@override
Future<Result<int>> getPageForVerse(int surahNumber, int verseNumber) async {
  final page = QuranPageData.getPageForVerse(surahNumber, verseNumber);
  
  if (page == null) {
    return ResultError(
      VerseNotFoundFailure(
        message: 'Could not find page for $surahNumber:$verseNumber',
      ),
    );
  }
  
  return Success(page);
}
```

**Example Queries**:
```dart
// Find which page contains Ayat al-Kursi (2:255)
final page = QuranPageData.getPageForVerse(2, 255);
print('Ayat al-Kursi is on page $page'); // Page 42

// Get first verse on page 1
final start = QuranPageData.getPageStart(1);
print('Page 1 starts at ${start[0]}:${start[1]}'); // 1:1 (Al-Fatihah verse 1)

// Get surah for page 200
final surah = QuranPageData.getSurahForPage(200);
print('Page 200 is in surah $surah'); // Surah 11 (Hud)
```

**Adding Juz Support** (Future Enhancement):
```dart
// Could add Juz boundaries similarly
static const Map<int, List<int>> juzStartMapping = {
  1: [1, 1],      // Juz 1: Al-Fatihah 1
  2: [2, 142],    // Juz 2: Al-Baqarah 142
  3: [2, 253],    // Juz 3: Al-Baqarah 253
  // ... 30 Juz
};

static int? getJuzForPage(int pageNumber) {
  // Calculate juz from page number
  return ((pageNumber - 1) ~/ 20) + 1; // Approximate: 20 pages per juz
}
```

---

## Data Source Patterns

### Pattern 1: Throw Failures, Don't Return Them
```dart
// ✅ Correct - throw Failure
Future<Map<String, dynamic>> getSurah(int surahNumber) async {
  if (response.statusCode != 200) {
    throw ServerFailure(message: 'API error');
  }
  return data;
}

// ❌ Wrong - returning Result is repository's job
Future<Result<Map<String, dynamic>>> getSurah(int surahNumber) async {
  if (response.statusCode != 200) {
    return ResultError(ServerFailure(...));
  }
  return Success(data);
}
```

### Pattern 2: HTTP Timeout Pattern
```dart
final response = await client.get(uri).timeout(
  const Duration(seconds: 30),
);
```

### Pattern 3: Validate Response Structure
```dart
if (data['status'] == 'OK' && data['data'] != null) {
  return data['data'];
} else {
  throw ServerFailure(message: 'Invalid response format');
}
```

### Pattern 4: Error Precedence
```dart
try {
  // API call
} on TimeoutException {        // 1. Timeout
  throw const TimeoutFailure();
} on http.ClientException {    // 2. Network error
  throw NetworkFailure(...);
} on FormatException {          // 3. JSON parse error
  throw ServerFailure(...);
} catch (e) {                   // 4. Unknown error
  if (e is Failure) rethrow;
  throw ServerFailure(message: '$e');
}
```

---

## Testing

### Mock HTTP Client
```dart
class MockHttpClient extends Mock implements http.Client {}

test('should return data on successful API call', () async {
  final mockClient = MockHttpClient();
  final dataSource = QuranRemoteDataSource(client: mockClient);
  
  when(mockClient.get(any, headers: anyNamed('headers')))
    .thenAnswer((_) async => http.Response(
      '{"status":"OK","data":{"number":1}}',
      200,
    ));
  
  final result = await dataSource.getSurah(1);
  
  expect(result['number'], 1);
});

test('should throw TimeoutFailure on timeout', () async {
  when(mockClient.get(any, headers: anyNamed('headers')))
    .thenThrow(TimeoutException('Timeout'));
  
  expect(
    () => dataSource.getSurah(1),
    throwsA(isA<TimeoutFailure>()),
  );
});

test('should throw NetworkFailure on ClientException', () async {
  when(mockClient.get(any, headers: anyNamed('headers')))
    .thenThrow(http.ClientException('No internet'));
  
  expect(
    () => dataSource.getSurah(1),
    throwsA(isA<NetworkFailure>()),
  );
});
```

---

## Common Pitfalls

### ❌ Pitfall 1: Returning Result Instead of Throwing
```dart
// ❌ WRONG
Future<Result<T>> getData() async {
  try {
    return Success(data);
  } catch (e) {
    return ResultError(Failure());
  }
}

// ✅ CORRECT
Future<T> getData() async {
  try {
    return data;
  } catch (e) {
    throw Failure();
  }
}
```

### ❌ Pitfall 2: No Timeout
```dart
// ❌ WRONG - can hang forever
final response = await client.get(uri);

// ✅ CORRECT
final response = await client.get(uri).timeout(Duration(seconds: 30));
```

### ❌ Pitfall 3: Not Validating Response
```dart
// ❌ WRONG - assumes data exists
final data = json.decode(response.body);
return data['data']; // Could be null!

// ✅ CORRECT
final data = json.decode(response.body);
if (data['status'] == 'OK' && data['data'] != null) {
  return data['data'];
} else {
  throw ServerFailure(message: 'Invalid response');
}
```

---

**Related Documentation**:
- See `lib/data/AGENTS.md` for data layer overview
- See `lib/data/repositories/AGENTS.md` for repository implementation
- See `lib/core/constants/AGENTS.md` for API endpoint constants
- See `lib/core/errors/AGENTS.md` for failure types
