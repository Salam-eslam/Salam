# Presentation Layer - AGENTS.md

## Overview
The `presentation` layer contains all UI components following the MVVM pattern with **Provider** for state management. It depends on the `domain` layer (use cases) but has no knowledge of the `data` layer.

## Directory Structure
```
presentation/
├── providers/      # State management (ChangeNotifier-based)
├── screens/        # Full-page UI components
└── widgets/        # Reusable UI components
```

## Core Concepts

### 1. Providers (State Management)
Providers extend `ChangeNotifier` and wrap domain use cases to expose UI state.

#### Provider Pattern
```dart
class SurahProvider with ChangeNotifier {
  final GetSurahUseCase _getSurahUseCase;
  
  // State
  List<Surah> _surahs = [];
  Surah? _currentSurah;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Surah> get surahs => _surahs;
  Surah? get currentSurah => _currentSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  SurahProvider(this._getSurahUseCase);
  
  Future<bool> loadSurah(int surahNumber) async {
    _setLoading(true);
    _clearError();
    
    final result = await _getSurahUseCase.execute(surahNumber);
    
    if (result is Success<Surah>) {
      _currentSurah = result.data;
      _setLoading(false);
      notifyListeners();
      return true;
    } else if (result is ResultError<Surah>) {
      _setError(result.failure.message);
      _setLoading(false);
      notifyListeners();
      return false;
    }
    
    return false;
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
```

**Key Providers**:
- `surah_provider.dart` - Surah data management
- `bookmarks_provider.dart` - Bookmark operations
- `enhanced_theme_provider.dart` - Theme/appearance settings
- `reading_progress_provider.dart` - Reading tracking
- `chat_history_provider.dart` - AI chat state
- `page_progress_provider.dart` - Mushaf page tracking
- `preference_settings_provider.dart` - User preferences
- `quran_page_provider.dart` - Page-based Quran reading

### 2. Provider Registration (main.dart)
```dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PreferenceSettingsProvider()),
      ChangeNotifierProvider.value(value: DependencyInjection.bookmarksProvider),
      ChangeNotifierProvider.value(value: DependencyInjection.surahProvider),
      ChangeNotifierProvider(create: (_) => EnhancedThemeProvider()),
      ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
      ChangeNotifierProvider(
        create: (_) => QuranPageProvider(DependencyInjection.quranRepository),
      ),
    ],
    child: const MyApp(),
  ),
);
```

### 3. Provider Usage in Widgets
```dart
class SurahListScreen extends StatefulWidget {
  @override
  _SurahListScreenState createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurahProvider>().loadAllSurahs();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch for changes
    return Consumer<SurahProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const EnhancedLoadingIndicator();
        }
        
        if (provider.errorMessage != null) {
          return ErrorWidget(message: provider.errorMessage!);
        }
        
        return ListView.builder(
          itemCount: provider.surahs.length,
          itemBuilder: (context, index) {
            final surah = provider.surahs[index];
            return SurahTile(surah: surah);
          },
        );
      },
    );
  }
}
```

**Provider Access Methods**:
- `context.read<T>()` - One-time read (e.g., calling methods)
- `context.watch<T>()` - Rebuild on change
- `Consumer<T>()` - Scoped rebuild
- `Provider.of<T>(context, listen: false)` - Legacy syntax for read

## Screens

### Screen Types
1. **Main Navigation** - `main_screen.dart` (bottom navigation)
2. **Quran Reading** 
   - `surah_list.dart` - List of all 114 surahs
   - `surah_reader.dart` - Verse-by-verse reading
   - `mushaf_reader.dart` - Page-based (604 pages) reading
3. **Prayer** - `prayer.dart` - Prayer times and Qibla
4. **Search** - `search.dart` - Verse/surah search
5. **Bookmarks** - `bookmark.dart` - Saved verses
6. **AI Assistant** - `islamic_ai_assistant_screen.dart` - GPT-4 Q&A
7. **Settings** 
   - `settings_screen.dart` - General settings
   - `accessibility_settings_screen.dart` - Accessibility options
   - `notification_settings_screen.dart` - Prayer notifications
8. **Other** - `onboarding_screen.dart`, `community_screen.dart`, `islamic_calendar_screen.dart`

### Screen Structure Pattern
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize state, load data
    _loadData();
  }
  
  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyProvider>().loadData();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Consumer<MyProvider>(
        builder: (context, provider, child) {
          // Build UI based on provider state
          return _buildContent(provider);
        },
      ),
    );
  }
  
  Widget _buildContent(MyProvider provider) {
    if (provider.isLoading) return EnhancedLoadingIndicator();
    if (provider.errorMessage != null) return ErrorDisplay(provider.errorMessage!);
    return _buildDataView(provider.data);
  }
  
  @override
  void dispose() {
    // Clean up controllers, subscriptions
    super.dispose();
  }
}
```

### Material 3 UI Patterns
```dart
// Use theme colors
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.titleLarge,
  ),
)

// Card with elevation
Card(
  elevation: 2,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(...),
  ),
)

// Filled button (Material 3)
FilledButton(
  onPressed: () {},
  child: Text('Action'),
)

// List tile with semantic widgets
ListTile(
  leading: Icon(Icons.book),
  title: Text('Title'),
  subtitle: Text('Subtitle'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {},
)
```

## Widgets

### Reusable Components
- `quran_page_widget.dart` - Mushaf page display
- `recent_reading_widget.dart` - Last read card
- `enhanced_loading.dart` - Custom loading indicators
- `enhanced_animations.dart` - Staggered/fade animations

### Widget Best Practices
```dart
// Stateless when no internal state
class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  const MyWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(title),
      ),
    );
  }
}
```

## Theme Management

### EnhancedThemeProvider
```dart
// Access theme provider
final themeProvider = context.read<EnhancedThemeProvider>();

// Change theme mode
themeProvider.setThemeMode(ThemeMode.dark);

// Change theme style (Islamic, Ocean, Sunset, etc.)
themeProvider.setThemeStyle(AppThemeStyle.islamic);

// Change Arabic font
themeProvider.setArabicFont(ArabicFontFamily.scheherazade);

// Font scaling (accessibility)
themeProvider.setFontScale(1.5); // 0.7 - 2.0

// High contrast mode
themeProvider.setHighContrast(true);

// Reading modes
themeProvider.setReadingMode(ReadingMode.night);
// Options: normal, night, comfort
```

### Reading Modes
```dart
enum ReadingMode {
  normal,   // Standard theme colors
  night,    // Deep blue bg, soft blue-white text
  comfort,  // Warm colors (cream bg in light mode)
}

// Get reading mode colors
final bgColor = themeProvider.getReadingModeBackgroundColor(context);
final textColor = themeProvider.getReadingModeTextColor(context);
```

## Navigation

### Navigation Pattern
```dart
// Push new screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SurahReaderScreen(surahNumber: 1),
  ),
);

// Pop back
Navigator.pop(context);

// Replace route
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

### Bottom Navigation (main_screen.dart)
```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() => _selectedIndex = index);
  },
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Quran'),
    BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Prayer'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
  ],
)
```

## Common Patterns

### Pattern 1: Load Data on Init
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<MyProvider>().loadData();
  });
}
```

### Pattern 2: Handle Loading/Error States
```dart
Widget build(BuildContext context) {
  return Consumer<MyProvider>(
    builder: (context, provider, _) {
      if (provider.isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (provider.errorMessage != null) {
        return Center(child: Text('Error: ${provider.errorMessage}'));
      }
      
      return _buildContent(provider);
    },
  );
}
```

### Pattern 3: Search with Debounce
```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}

void _performSearch(String query) {
  final results = _allItems.where((item) {
    return item.name.toLowerCase().contains(query.toLowerCase());
  }).toList();
  
  setState(() => _filteredItems = results);
}
```

### Pattern 4: Staggered Animations
```dart
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: ItemWidget(items[index]),
        ),
      ),
    );
  },
)
```

## Accessibility Features

### Text-to-Speech
```dart
// In accessibility_service.dart
final tts = FlutterTts();
await tts.setLanguage('ar'); // Arabic
await tts.speak(arabicText);

// Stop speaking
await tts.stop();
```

### Semantic Widgets
```dart
// Add screen reader labels
Semantics(
  label: 'Surah Al-Fatiha, 7 verses',
  child: ListTile(...),
)

// Button semantics
Semantics(
  button: true,
  label: 'Play audio',
  child: IconButton(...),
)
```

### High Contrast Mode
```dart
// Check if high contrast is enabled
final isHighContrast = context.read<EnhancedThemeProvider>().isHighContrast;

// Apply high contrast colors
final textColor = isHighContrast 
  ? Colors.white 
  : Theme.of(context).textTheme.bodyLarge!.color;
```

## Adding New Features

### 1. Create Provider
```dart
// providers/my_provider.dart
class MyProvider with ChangeNotifier {
  final MyUseCase _useCase;
  
  List<MyEntity> _data = [];
  bool _isLoading = false;
  String? _error;
  
  List<MyEntity> get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  MyProvider(this._useCase);
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _useCase.execute();
    
    if (result is Success<List<MyEntity>>) {
      _data = result.data;
    } else if (result is ResultError<List<MyEntity>>) {
      _error = result.failure.message;
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
```

### 2. Register Provider
```dart
// main.dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (_) => MyProvider(DependencyInjection.myUseCase),
    ),
  ],
  child: MyApp(),
)
```

### 3. Create Screen
```dart
// screens/my_screen.dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Consumer<MyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return CircularProgressIndicator();
          return ListView.builder(
            itemCount: provider.data.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(provider.data[index].name));
            },
          );
        },
      ),
    );
  }
}
```

### 4. Add to Navigation
```dart
// In main_screen.dart or other screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyScreen()),
    );
  },
  child: Text('Open My Screen'),
)
```

## Common Mistakes

### ❌ Don't: Access provider without context
```dart
final provider = SurahProvider(); // WRONG - creates new instance
```

### ✅ Do: Access via context
```dart
final provider = context.read<SurahProvider>(); // CORRECT
```

### ❌ Don't: Use watch in callbacks
```dart
onPressed: () {
  context.watch<MyProvider>().doAction(); // WRONG - causes rebuild loop
}
```

### ✅ Do: Use read for actions
```dart
onPressed: () {
  context.read<MyProvider>().doAction(); // CORRECT
}
```

### ❌ Don't: Forget notifyListeners
```dart
void updateData(T data) {
  _data = data;
  // WRONG - UI won't update
}
```

### ✅ Do: Call notifyListeners
```dart
void updateData(T data) {
  _data = data;
  notifyListeners(); // CORRECT
}
```

---

**Related Documentation**:
- See `/AGENTS.md` for overall architecture
- See `lib/domain/AGENTS.md` for use cases
- See `lib/core/AGENTS.md` for theme configuration
- See `lib/services/AGENTS.md` for external service integration
