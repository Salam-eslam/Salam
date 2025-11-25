# Presentation Providers - AGENTS.md

## Overview
Providers implement **state management** using Flutter's `ChangeNotifier`. Each provider wraps one or more use cases and exposes UI state.

**Key Patterns**:
- Extend `ChangeNotifier`
- Inject use cases via constructor
- Call `notifyListeners()` after state changes
- Expose loading/error states
- Return bool/void from async operations (UI checks state)

## Files

### 1. `surah_provider.dart`
**Purpose**: Manage Surah list and current surah state.

```dart
class SurahProvider extends ChangeNotifier {
  final GetSurahUseCase _getSurahUseCase;
  
  List<Surah> _surahs = [];
  Surah? _currentSurah;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Surah> get surahs => _surahs;
  Surah? get currentSurah => _currentSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<bool> loadSurah(int surahNumber) async {
    _setLoading(true);
    final result = await _getSurahUseCase.execute(surahNumber);
    
    if (result is Success<Surah>) {
      _currentSurah = result.data;
      _setLoading(false);
      return true;
    } else {
      _setError((result as ResultError).failure.message);
      _setLoading(false);
      return false;
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

**Usage**:
```dart
// In screen
final provider = context.read<SurahProvider>();
await provider.loadSurah(1);

if (provider.currentSurah != null) {
  // Display surah
} else if (provider.errorMessage != null) {
  // Show error
}
```

---

### 2. `bookmarks_provider.dart`
**Purpose**: Manage user bookmarks.

```dart
class BookmarksProvider extends ChangeNotifier {
  final ManageBookmarksUseCase _manageBookmarksUseCase;
  
  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  Future<bool> addBookmark(int surah, int verse, {String? note}) async {
    final result = await _manageBookmarksUseCase.addBookmark(
      surahNumber: surah,
      verseNumber: verse,
      note: note,
    );
    
    if (result is Success) {
      await refreshBookmarks();
      return true;
    }
    return false;
  }
  
  Future<void> refreshBookmarks() async {
    final result = await _manageBookmarksUseCase.getAllBookmarks();
    if (result is Success<List<Bookmark>>) {
      _bookmarks = result.data;
      notifyListeners();
    }
  }
}
```

---

### 3. `enhanced_theme_provider.dart`
**Purpose**: Manage theme settings (dark mode, font scale, theme style).

```dart
class EnhancedThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _themeStyle = AppThemeStyle.islamic;
  ArabicFontFamily _arabicFont = ArabicFontFamily.cairo;
  double _fontScale = 1.0;
  bool _isHighContrast = false;
  
  ThemeData get lightTheme => AppTheme.lightTheme(
    style: _themeStyle,
    arabicFont: _arabicFont,
    fontScale: _fontScale,
    isHighContrast: _isHighContrast,
  );
  
  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.7, 2.0);
    notifyListeners();
  }
}
```

---

### 4. `reading_progress_provider.dart`
**Purpose**: Track and restore reading position.

```dart
class ReadingProgressProvider extends ChangeNotifier {
  ReadingProgress? _progress;
  
  Future<void> loadProgress() async {
    final result = await _repository.getReadingProgress();
    if (result is Success<ReadingProgress?>) {
      _progress = result.data;
      notifyListeners();
    }
  }
  
  Future<void> saveProgress(int surah, int verse, int page) async {
    await _repository.saveReadingProgress(surah, verse, page);
    await loadProgress();
  }
}
```

---

### 5. `quran_page_provider.dart`
**Purpose**: Manage Mushaf page navigation.

```dart
class QuranPageProvider extends ChangeNotifier {
  int _currentPage = 1;
  QuranPage? _currentPageData;
  
  Future<void> goToPage(int pageNumber) async {
    _currentPage = pageNumber.clamp(1, 604);
    await _loadPageData();
  }
  
  Future<void> nextPage() async {
    if (_currentPage < 604) {
      _currentPage++;
      await _loadPageData();
    }
  }
}
```

---

### 6. `preference_settings_provider.dart`
**Purpose**: Manage all user preferences.

```dart
class PreferenceSettingsProvider extends ChangeNotifier {
  UserPreferences _preferences = UserPreferences.defaultSettings();
  
  void updateReadingSetting({
    bool? showTranslation,
    String? translationLanguage,
  }) {
    _preferences = _preferences.copyWith(
      reading: _preferences.reading.copyWith(
        showTranslation: showTranslation,
        translationLanguage: translationLanguage,
      ),
    );
    _saveToStorage();
    notifyListeners();
  }
}
```

---

### 7. `chat_history_provider.dart`
**Purpose**: Manage AI chat messages.

```dart
class ChatHistoryProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(text: text, isUser: true);
    _messages.add(userMessage);
    notifyListeners();
    
    _isTyping = true;
    notifyListeners();
    
    final response = await _islamicAIService.askQuestion(text);
    
    _isTyping = false;
    _messages.add(ChatMessage(text: response, isUser: false));
    notifyListeners();
  }
}
```

---

### 8. `page_progress_provider.dart`
**Purpose**: Track which pages user has completed.

```dart
class PageProgressProvider extends ChangeNotifier {
  Map<int, bool> _completedPages = {};
  
  void markPageCompleted(int pageNumber) {
    _completedPages[pageNumber] = true;
    _saveProgress();
    notifyListeners();
  }
  
  bool isPageCompleted(int pageNumber) {
    return _completedPages[pageNumber] ?? false;
  }
  
  double get overallProgress {
    return _completedPages.length / 604.0;
  }
}
```

---

### 9. `cache_provider.dart`
**Purpose**: Manage offline cache and storage.

```dart
class CacheProvider extends ChangeNotifier {
  int _cachedSurahs = 0;
  double _cacheSize = 0.0;
  
  Future<void> cacheAllSurahs() async {
    for (int i = 1; i <= 114; i++) {
      await _repository.getSurah(i); // Triggers caching
      _cachedSurahs = i;
      notifyListeners();
    }
  }
  
  Future<void> clearCache() async {
    await Hive.deleteBoxFromDisk('surahs');
    _cachedSurahs = 0;
    notifyListeners();
  }
}
```

---

## Provider Patterns

### Pattern 1: Private State with Public Getters
```dart
class MyProvider extends ChangeNotifier {
  String _data = '';  // Private
  
  String get data => _data;  // Public getter
  
  void updateData(String newData) {
    _data = newData;
    notifyListeners();
  }
}
```

### Pattern 2: Loading/Error States
```dart
class MyProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;  // Clear error on new operation
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}
```

### Pattern 3: Async Operations Return Bool
```dart
Future<bool> doSomething() async {
  _setLoading(true);
  final result = await _useCase.execute();
  
  if (result is Success) {
    _data = result.data;
    _setLoading(false);
    return true;  // Success
  } else {
    _setError((result as ResultError).failure.message);
    return false;  // Failure
  }
}
```

### Pattern 4: MultiProvider Setup
```dart
// main.dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DependencyInjection.surahProvider),
      ChangeNotifierProvider(create: (_) => DependencyInjection.bookmarksProvider),
      ChangeNotifierProvider(create: (_) => EnhancedThemeProvider()),
    ],
    child: MyApp(),
  ),
);
```

---

## Testing Providers

```dart
test('should load surah successfully', () async {
  // Arrange
  when(mockUseCase.execute(1)).thenAnswer(
    (_) async => Success(validSurah),
  );
  
  final provider = SurahProvider(mockUseCase);
  
  // Act
  final result = await provider.loadSurah(1);
  
  // Assert
  expect(result, true);
  expect(provider.currentSurah, equals(validSurah));
  expect(provider.isLoading, false);
});

test('should set error on failure', () async {
  when(mockUseCase.execute(999)).thenAnswer(
    (_) async => ResultError(SurahNotFoundFailure(message: 'Not found')),
  );
  
  final provider = SurahProvider(mockUseCase);
  final result = await provider.loadSurah(999);
  
  expect(result, false);
  expect(provider.errorMessage, isNotNull);
  expect(provider.currentSurah, isNull);
});
```

---

**Related Documentation**:
- See `lib/presentation/AGENTS.md` for presentation layer overview
- See `lib/domain/usecases/AGENTS.md` for use case structure
- See `lib/presentation/screens/AGENTS.md` for provider usage in UI
