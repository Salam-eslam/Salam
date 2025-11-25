# Presentation Screens - AGENTS.md

## Overview
Screens are full-page widgets representing app routes. Each screen typically consumes one or more providers and displays data/UI.

## Files (17 Screens)

### Core Reading Screens

**1. `surah_list.dart`**
- Displays all 114 surahs in a list
- Filterable by Meccan/Medinan
- Shows surah number, name (Arabic + English), verse count
- Tapping navigates to `surah_reader.dart`

**2. `surah_reader.dart`**
- Displays one surah with all verses
- Shows translation, transliteration (optional)
- Verse-by-verse audio playback
- Bookmark verses
- Share verses

**3. `mushaf_reader.dart`**
- Displays Quran by pages (1-604)
- Mimics physical Mushaf layout
- Swipe to change pages
- Shows Juz boundaries

**4. `quran_reader.dart`**
- Unified reader (switches between surah/mushaf modes)
- Reading settings panel
- Font scaling, theme toggle
- Progress tracking

---

### Search & Bookmarks

**5. `search.dart`**
- Search Arabic text or translations
- Filter by surah
- Shows verse context
- Tap to navigate to verse

**6. `bookmark.dart`**
- List all saved bookmarks
- Sort by date/surah
- Edit notes
- Delete bookmarks

---

### Prayer & Qibla

**7. `prayer.dart`**
- Display today's prayer times
- Countdown to next prayer
- Location-based calculation
- Notification settings

**8. `qibla.dart`**
- Compass pointing to Mecca
- Uses device sensors
- Shows distance to Kaaba
- Requires location permission

---

### AI & Community

**9. `ai_assistant.dart`**
- Chat interface with GPT-4
- Ask Islamic questions
- Constrained to Islamic topics
- Chat history persistence

**10. `community.dart`**
- Community features (future)
- Discussion forums
- Shared reflections
- Social features

---

### Settings & Preferences

**11. `settings.dart`**
- Master settings screen
- Theme selection
- Language preferences
- Notification settings
- Cache management

**12. `preference_settings.dart`**
- Detailed preference editor
- Reading mode (surah/mushaf)
- Translation language
- Reciter selection
- Font family & size

**13. `accessibility.dart`**
- Accessibility features
- Text-to-speech settings
- High contrast mode
- Screen reader support
- Font scaling

**14. `cache_management.dart`**
- View cached data
- Cache all surahs
- Clear cache
- Storage usage stats

---

### Onboarding & Misc

**15. `onboarding.dart`**
- First-time user setup
- Feature introduction
- Permission requests
- Theme selection

**16. `main_screen.dart`**
- Home/dashboard
- Recently read surahs
- Prayer times widget
- Quick actions
- Bottom navigation

**17. `notifications.dart`**
- Notification history
- Manage notification preferences
- Daily ayah settings

---

### Islamic Calendar

**18. `calendar.dart`**
- Islamic calendar view
- Hijri date conversion
- Important Islamic dates
- Event reminders

---

## Screen Patterns

### Pattern 1: Provider Consumption
```dart
class SurahListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurahProvider>();
    
    if (provider.isLoading) {
      return LoadingWidget();
    }
    
    if (provider.errorMessage != null) {
      return ErrorWidget(provider.errorMessage!);
    }
    
    return ListView.builder(
      itemCount: provider.surahs.length,
      itemBuilder: (context, index) {
        final surah = provider.surahs[index];
        return SurahTile(surah: surah);
      },
    );
  }
}
```

### Pattern 2: Navigation
```dart
// Navigate to surah reader
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SurahReaderScreen(surahNumber: 1),
  ),
);

// Or with named routes
Navigator.pushNamed(
  context,
  '/surah-reader',
  arguments: {'surahNumber': 1},
);
```

### Pattern 3: Screen Lifecycle
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyProvider>().loadData();
    });
  }
  
  @override
  void dispose() {
    // Cleanup
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) { /* ... */ }
}
```

---

## Routing

**main.dart Routes**:
```dart
routes: {
  '/': (_) => MainScreen(),
  '/surah-list': (_) => SurahListScreen(),
  '/surah-reader': (_) => SurahReaderScreen(),
  '/mushaf-reader': (_) => MushafReaderScreen(),
  '/search': (_) => SearchScreen(),
  '/bookmarks': (_) => BookmarkScreen(),
  '/prayer': (_) => PrayerScreen(),
  '/qibla': (_) => QiblaScreen(),
  '/ai-assistant': (_) => AIAssistantScreen(),
  '/settings': (_) => SettingsScreen(),
},
```

---

**Related Documentation**:
- See `lib/presentation/AGENTS.md` for presentation overview
- See `lib/presentation/providers/AGENTS.md` for state management
- See `lib/presentation/widgets/AGENTS.md` for reusable components
