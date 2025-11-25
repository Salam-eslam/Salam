# Architecture Violations & Fixes

**Created:** November 16, 2025  
**Last Updated:** November 16, 2025
**Status:** Phase 2 Complete ✅

## Overview
This document tracks violations of Clean Architecture principles in the Salam codebase and their resolution status.

---

## ✅ RESOLVED: Violation #1: QuranService Duplication

### Resolution Date: November 16, 2025

**Status:** ✅ **FIXED** - Clean architecture properly implemented!

### What Was Done

**Phase 2 Implementation** (Completed):

1. ✅ **Repository Methods Added** (`quran_repository.dart`):
   - `getSurahTranslations()` - Offline-first with 7-day Hive caching
   - `getVerseTranslation()` - Delegates to surah translations
   - `getVerseTafsir()` - Offline-first with 30-day Hive caching
   - `getAvailableTafsirs()` - Lists available commentary sources

2. ✅ **Use Cases Created** (5 new files):
   - `GetSurahTranslationsUseCase` - Business validation for translations
   - `GetVerseTranslationUseCase` - Single verse translation
   - `GetAvailableTranslationsUseCase` - Lists translation editions
   - `GetVerseTafsirUseCase` - Business validation for tafsir
   - `GetAvailableTafsirsUseCase` - Lists tafsir sources

3. ✅ **Providers Implemented** (2 new files):
   - `TranslationProvider` - State management for translations
   - `TafsirProvider` - State management for tafsir/commentary

4. ✅ **Dependency Injection Updated**:
   - Extended `DependencyInjection` with 5 use cases and 2 providers
   - Added factory methods for provider creation

5. ✅ **Presentation Layer Migrated**:
   - Updated `main.dart` - Added providers to MultiProvider
   - Refactored `surah_reader.dart` - Removed QuranService dependency
   - Now uses `TranslationProvider` and `TafsirProvider` exclusively

6. ✅ **QuranService Refactored**:
   - **REMOVED** `getTranslations()` method (now in repository)
   - **REMOVED** `getTafsir()` method (now in repository)
   - **REMOVED** unused imports (`translation.dart`, `tafsir.dart`, `logger_service.dart`)
   - **KEPT** audio URL generation (not yet migrated)
   - **KEPT** repository-enhanced surah access (backward compatibility)

### New Architecture (✅ Working!)

```
┌─────────────────────────────────────────────────────────────────────┐
│ Presentation Layer                                                  │
│ ┌─────────────┐                                                     │
│ │surah_reader │ → TranslationProvider → GetSurahTranslationsUseCase│
│ └─────────────┘              ↓                      ↓               │
│                        TafsirProvider    →   GetVerseTafsirUseCase  │
│                                                      ↓               │
│                                              QuranRepository         │
│                                                      ↓               │
│                                         [Hive Cache] → [API]        │
└─────────────────────────────────────────────────────────────────────┘
```

### Original Problem (FIXED)
**File:** `lib/services/quran_service.dart`

**Problem:**
- The service layer contains `QuranService` which duplicates repository functionality
- It directly makes API calls for translations and tafsir
- `surah_reader.dart` bypasses the clean architecture by directly using this service

**Code Smell:**
```dart
// In services/quran_service.dart
Future<TranslationSet> getTranslations(int surahNumber, List<String> editions) async {
  final url = '$baseUrl/surah/$surahNumber/editions/$editionsParam';
  final response = await http.get(Uri.parse(url)); // Direct API call!
  // ...
}

// In presentation/screens/surah_reader.dart
final translations = await _quranService.getTranslations(...); // Bypassing architecture!
```

**Why It's Wrong:**
1. **Layer Violation:** Presentation layer should not directly call services for data operations
2. **Duplication:** Repository already defines these methods but they're not implemented
3. **No Caching:** Service layer doesn't use the offline-first Hive caching
4. **No Error Handling:** Doesn't use the Result<T> pattern
5. **Testing Difficulty:** Direct service calls are hard to mock

### Impact
- **Severity:** High
- **Files Affected:** 
  - `lib/services/quran_service.dart` (238 lines)
  - `lib/presentation/screens/surah_reader.dart` (uses service directly)

### Proper Architecture
```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer                                          │
│ ┌─────────────┐                                             │
│ │surah_reader │ → Provider → Use Case → Repository → API   │
│ └─────────────┘                                             │
└─────────────────────────────────────────────────────────────┘

NOT: surah_reader → QuranService → API (WRONG!)
```

### Fix Plan

#### Step 1: Implement Repository Methods (Phase 2)
Complete the translation and tafsir methods in `QuranRepository`:

```dart
// lib/data/repositories/quran_repository.dart
@override
Future<Result<List<String>>> getSurahTranslations(
  int surahNumber,
  String translationKey,
) async {
  try {
    // 1. Check cache
    final cached = await _translationCache.get(key);
    if (cached != null && !cached.isExpired) {
      return Success(cached.translations);
    }
    
    // 2. Fetch from API
    final translations = await remoteDataSource.getSurahTranslations(
      surahNumber,
      translationKey,
    );
    
    // 3. Cache result
    await _translationCache.put(key, translations);
    
    return Success(translations);
  } catch (e) {
    return ResultError(ServerFailure(message: 'Failed to load translations'));
  }
}
```

#### Step 2: Create Use Cases
```dart
// lib/domain/usecases/get_surah_translations_usecase.dart
class GetSurahTranslationsUseCase {
  final QuranRepositoryInterface repository;
  
  const GetSurahTranslationsUseCase(this.repository);
  
  Future<Result<List<String>>> execute({
    required int surahNumber,
    required String translationKey,
  }) async {
    // Business logic validation
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(InvalidInputFailure(message: 'Invalid surah number'));
    }
    
    return await repository.getSurahTranslations(surahNumber, translationKey);
  }
}
```

#### Step 3: Create Providers
```dart
// lib/presentation/providers/translation_provider.dart
class TranslationProvider with ChangeNotifier {
  final GetSurahTranslationsUseCase _getTranslationsUseCase;
  
  List<String>? _translations;
  bool _isLoading = false;
  String? _error;
  
  Future<void> loadTranslations(int surahNumber, String translationKey) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _getTranslationsUseCase.execute(
      surahNumber: surahNumber,
      translationKey: translationKey,
    );
    
    if (result is Success<List<String>>) {
      _translations = result.data;
      _error = null;
    } else if (result is ResultError<List<String>>) {
      _error = result.failure.message;
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
```

#### Step 4: Update Presentation Layer
```dart
// lib/presentation/screens/surah_reader.dart
// OLD (WRONG):
final translations = await _quranService.getTranslations(...);

// NEW (CORRECT):
final translationProvider = context.read<TranslationProvider>();
await translationProvider.loadTranslations(surahNumber, translationKey);
```

#### Step 5: Refactor QuranService
After implementing proper architecture, `QuranService` should:
- **Keep:** Audio URL generation (if it's truly a service concern)
- **Remove:** All data fetching methods (translations, tafsir, surahs)
- **Possibly Rename:** To `AudioService` if only audio remains

---

## Violation #2: Domain Layer Dependencies ✅

### Status: **VERIFIED CLEAN**

Checked domain layer for violations:
```bash
grep -r "import.*data" lib/domain/
grep -r "import.*presentation" lib/domain/
grep -r "import.*services" lib/domain/
```

**Result:** ✅ No violations found. Domain layer correctly has no dependencies on outer layers.

---

## Summary

| Violation | Severity | Status | Fix Phase |
|-----------|----------|--------|-----------|
| QuranService duplication | High | Documented | Phase 2 |
| Domain layer dependencies | N/A | Clean ✅ | N/A |

---

## Next Steps

1. **Phase 1 (Week 1-2):** ✅ COMPLETED
   - Clean dead code ✅
   - Implement logging ✅
   - Document violations ✅

2. **Phase 2 (Week 3-4):** 🔄 READY TO START
   - Implement translation/tafsir methods in repository
   - Create 15+ use cases for all repository operations
   - Create providers for each use case
   - Update all presentation layer to use providers

3. **Phase 3 (Week 5-6):** Testing
   - Unit tests for use cases
   - Widget tests for screens
   - Integration tests

---

## Notes

- The current `QuranService` is a temporary bridge while the repository methods are being implemented
- Removing it prematurely would break the app
- The fix requires implementing the full use case layer first
- This is a **non-breaking refactor** - can be done incrementally

**Estimated Effort:** 2 weeks (Phase 2)  
**Lines to Refactor:** ~500 lines  
**New Files to Create:** ~20 files (use cases + providers)
