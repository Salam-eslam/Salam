# Domain Entities - AGENTS.md

## Overview
Pure business objects representing core concepts in the Salam app. Entities contain **zero framework dependencies** - no Flutter, no packages, just Dart. They define the "vocabulary" of the domain with rich business logic.

**Key Principle**: Entities are immutable value objects with business rules. They live in the innermost layer of Clean Architecture.

## Files

### 1. `surah_entity.dart`
Represents a Surah (chapter) of the Quran with verses.

**Core Structure**:
```dart
class Surah {
  final int number;                      // 1-114
  final String name;                     // Arabic name (e.g., 'الفاتحة')
  final String englishName;              // English name (e.g., 'Al-Fatihah')
  final String englishNameTranslation;   // Meaning (e.g., 'The Opening')
  final String revelationType;           // 'Meccan' or 'Medinan'
  final int numberOfAyahs;               // Total verses in surah
  final List<Verse> verses;              // Complete verse list
  
  const Surah({...}); // Immutable constructor
}

class Verse {
  final int number;                      // Verse number in Quran (1-6236)
  final int numberInSurah;               // Verse number in this surah (1-286)
  final String arabicText;               // Arabic Quranic text
  final String? translation;             // English translation (optional)
  final String? transliteration;         // Romanized Arabic (optional)
  final String? tafsir;                  // Interpretation (optional)
  final bool isBookmarked;               // User bookmark flag
  final DateTime? lastReadAt;            // Last read timestamp
  
  const Verse({...});
}
```

**Business Logic Methods**:
```dart
// Revelation type checks
bool get isMeccan => revelationType.toLowerCase() == 'meccan';
bool get isMedinan => revelationType.toLowerCase() == 'medinan';

// Statistics
int get totalCharacters => verses.fold(0, (sum, v) => sum + v.arabicText.length);

// Bookmarks
List<Verse> get bookmarkedVerses => verses.where((v) => v.isBookmarked).toList();
bool get hasBookmarks => verses.any((v) => v.isBookmarked);

// Verse lookup
Verse? getVerse(int verseNumber) {
  try {
    return verses.firstWhere((v) => v.number == verseNumber);
  } catch (e) {
    return null;
  }
}

// Search
List<Verse> searchVerses(String query) {
  return verses.where((v) => 
    v.arabicText.contains(query) || 
    (v.translation?.toLowerCase().contains(query.toLowerCase()) ?? false)
  ).toList();
}
```

**Equality & Hashing**:
```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is Surah &&
    other.number == number &&
    other.name == name &&
    other.englishName == englishName;
}

@override
int get hashCode => number.hashCode ^ name.hashCode;
```

**Usage Example**:
```dart
// In use case
final result = await repository.getSurah(1);
if (result is Success<Surah>) {
  final surah = result.data;
  
  print('${surah.englishName} (${surah.name})');
  print('Revelation: ${surah.isMeccan ? "Meccan" : "Medinan"}');
  print('Verses: ${surah.numberOfAyahs}');
  
  // Find verse
  final verse = surah.getVerse(1);
  if (verse != null) {
    print('Verse ${verse.numberInSurah}: ${verse.arabicText}');
  }
  
  // Search
  final results = surah.searchVerses('الحمد');
  print('Found ${results.length} verses with "الحمد"');
}
```

---

### 2. `quran_page_entity.dart`
Represents a page in the Mushaf (physical Quran) format.

**Core Structure**:
```dart
class QuranPage {
  final int pageNumber;       // 1-604
  final int juzNumber;        // 1-30 (Juz/Para)
  final List<PageAyah> ayahs; // Verses on this page
  final String? juzName;      // Juz name in Arabic
  
  QuranPage({...});
}

class PageAyah {
  final int surahNumber;         // 1-114
  final String surahName;        // English surah name
  final String surahNameArabic;  // Arabic surah name
  final int ayahNumber;          // Verse number in Quran
  final String text;             // Arabic text
  final int numberInSurah;       // Verse number in surah
  
  PageAyah({...});
}
```

**Key Difference from Surah Entity**:
- **Surah**: Organized by chapter (logical grouping)
- **QuranPage**: Organized by physical Mushaf pages (visual representation)
- A page can contain verses from multiple surahs
- Used for Mushaf-style reading experience

**Serialization**:
```dart
factory QuranPage.fromJson(Map<String, dynamic> json) {
  return QuranPage(
    pageNumber: json['page'] as int,
    juzNumber: json['juz'] as int,
    ayahs: (json['ayahs'] as List)
        .map((ayah) => PageAyah.fromJson(ayah))
        .toList(),
    juzName: json['juzName'] as String?,
  );
}

Map<String, dynamic> toJson() {
  return {
    'page': pageNumber,
    'juz': juzNumber,
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
    'juzName': juzName,
  };
}
```

**Usage Example**:
```dart
// Get page 1 (Al-Fatihah)
final page = QuranPage(
  pageNumber: 1,
  juzNumber: 1,
  ayahs: [
    PageAyah(
      surahNumber: 1,
      surahName: 'Al-Fatihah',
      surahNameArabic: 'الفاتحة',
      ayahNumber: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      numberInSurah: 1,
    ),
    // ... verses 2-7
  ],
);

// Access verses
for (final ayah in page.ayahs) {
  print('Surah ${ayah.surahNumber}, Verse ${ayah.numberInSurah}');
  print(ayah.text);
}
```

---

### 3. `prayer_times_entity.dart`
Represents daily Islamic prayer times for a location.

**Core Structure**:
```dart
class PrayerTimes {
  static const int defaultPrayerTimeWindowMinutes = 15; // Detection window
  
  final DateTime fajr;     // Dawn prayer
  final DateTime sunrise;  // Sunrise (not a prayer, end of Fajr time)
  final DateTime dhuhr;    // Noon prayer
  final DateTime asr;      // Afternoon prayer
  final DateTime maghrib;  // Sunset prayer
  final DateTime isha;     // Night prayer
  final DateTime date;     // Date for these times
  final Location location; // Geographic location
  
  const PrayerTimes({...});
}

class Prayer {
  final String name;         // 'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'
  final DateTime time;       // Exact prayer time
  final PrayerType type;     // Enum for prayer identification
  
  const Prayer({...});
}

enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

class Location {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String? timezone;
  
  const Location({...});
}
```

**Business Logic Methods**:
```dart
// Get all prayers in chronological order
List<Prayer> get allPrayers => [
  Prayer(name: 'Fajr', time: fajr, type: PrayerType.fajr),
  Prayer(name: 'Dhuhr', time: dhuhr, type: PrayerType.dhuhr),
  Prayer(name: 'Asr', time: asr, type: PrayerType.asr),
  Prayer(name: 'Maghrib', time: maghrib, type: PrayerType.maghrib),
  Prayer(name: 'Isha', time: isha, type: PrayerType.isha),
];

// Get next prayer from current time
Prayer? getNextPrayer([DateTime? currentTime]) {
  final now = currentTime ?? DateTime.now();
  
  for (final prayer in allPrayers) {
    if (prayer.time.isAfter(now)) {
      return prayer;
    }
  }
  
  // If no prayer today, return tomorrow's Fajr
  return Prayer(
    name: 'Fajr',
    time: fajr.add(const Duration(days: 1)),
    type: PrayerType.fajr,
  );
}

// Get previous prayer
Prayer? getPreviousPrayer([DateTime? currentTime]) {
  final now = currentTime ?? DateTime.now();
  Prayer? previous;
  
  for (final prayer in allPrayers) {
    if (prayer.time.isAfter(now)) break;
    previous = prayer;
  }
  
  return previous ?? Prayer(
    name: 'Isha',
    time: isha.subtract(const Duration(days: 1)),
    type: PrayerType.isha,
  );
}

// Check if currently in prayer time window
Prayer? getCurrentPrayer([DateTime? currentTime, int windowMinutes = 15]) {
  final now = currentTime ?? DateTime.now();
  
  for (final prayer in allPrayers) {
    final windowStart = prayer.time.subtract(Duration(minutes: windowMinutes));
    final windowEnd = prayer.time.add(Duration(minutes: windowMinutes));
    
    if (now.isAfter(windowStart) && now.isBefore(windowEnd)) {
      return prayer;
    }
  }
  
  return null;
}

// Time remaining until next prayer
Duration? getTimeUntilNextPrayer([DateTime? currentTime]) {
  final nextPrayer = getNextPrayer(currentTime);
  if (nextPrayer == null) return null;
  
  final now = currentTime ?? DateTime.now();
  return nextPrayer.time.difference(now);
}
```

**Usage Example**:
```dart
// Create prayer times
final prayerTimes = PrayerTimes(
  fajr: DateTime(2025, 1, 15, 5, 30),
  sunrise: DateTime(2025, 1, 15, 6, 45),
  dhuhr: DateTime(2025, 1, 15, 12, 15),
  asr: DateTime(2025, 1, 15, 15, 30),
  maghrib: DateTime(2025, 1, 15, 17, 45),
  isha: DateTime(2025, 1, 15, 19, 0),
  date: DateTime(2025, 1, 15),
  location: Location(
    latitude: 24.7136,
    longitude: 46.6753,
    city: 'Riyadh',
    country: 'Saudi Arabia',
  ),
);

// Get next prayer
final next = prayerTimes.getNextPrayer();
if (next != null) {
  print('Next prayer: ${next.name} at ${next.time}');
  
  final timeRemaining = prayerTimes.getTimeUntilNextPrayer();
  print('Time remaining: ${timeRemaining?.inMinutes} minutes');
}

// Check if in prayer window
final current = prayerTimes.getCurrentPrayer(DateTime.now(), 15);
if (current != null) {
  print('It\'s time for ${current.name} prayer!');
}
```

---

### 4. `user_preferences_entity.dart`
Comprehensive user settings and preferences.

**Core Structure** (Nested Value Objects):
```dart
class UserPreferences {
  final ThemeSettings theme;
  final ReadingSettings reading;
  final AccessibilitySettings accessibility;
  final NotificationSettings notifications;
  final AudioSettings audio;
  final LocationSettings location;
  
  const UserPreferences({...});
  
  static UserPreferences defaultSettings() { /* ... */ }
  
  UserPreferences copyWith({...}) { /* ... */ }
}
```

**Sub-entities**:

**1. ThemeSettings**:
```dart
class ThemeSettings {
  final bool isDarkMode;
  final String themeStyle;        // 'islamic', 'ocean', 'sunset', etc.
  final String arabicFont;        // 'Cairo', 'Amiri', 'Scheherazade', etc.
  final double fontScale;         // 0.7 - 2.0
  final bool isHighContrast;
  final bool useDynamicColors;
  
  static ThemeSettings defaultSettings() => ThemeSettings(
    isDarkMode: false,
    themeStyle: 'islamic',
    arabicFont: 'Cairo',
    fontScale: 1.0,
    isHighContrast: false,
    useDynamicColors: true,
  );
}
```

**2. ReadingSettings**:
```dart
class ReadingSettings {
  final String lastReadSurah;      // Surah number as string
  final int lastReadVerse;         // Verse number
  final int lastReadPage;          // Mushaf page
  final bool showTranslation;
  final String translationLanguage; // 'en', 'ur', 'id', etc.
  final bool showTransliteration;
  final bool enableAutoScroll;
  final double scrollSpeed;        // Auto-scroll speed
  final String readingMode;        // 'surah' or 'mushaf'
  
  static ReadingSettings defaultSettings() => ReadingSettings(
    lastReadSurah: '1',
    lastReadVerse: 1,
    lastReadPage: 1,
    showTranslation: true,
    translationLanguage: 'en',
    showTransliteration: false,
    enableAutoScroll: false,
    scrollSpeed: 1.0,
    readingMode: 'surah',
  );
}
```

**3. AccessibilitySettings**:
```dart
class AccessibilitySettings {
  final bool screenReaderEnabled;
  final bool textToSpeechEnabled;
  final double ttsSpeed;           // 0.5 - 2.0
  final String ttsLanguage;        // 'ar', 'en'
  final bool hapticFeedbackEnabled;
  final bool reduceAnimations;
  final double contrastLevel;      // 1.0 - 2.0
  
  static AccessibilitySettings defaultSettings() => AccessibilitySettings(
    screenReaderEnabled: false,
    textToSpeechEnabled: false,
    ttsSpeed: 1.0,
    ttsLanguage: 'ar',
    hapticFeedbackEnabled: true,
    reduceAnimations: false,
    contrastLevel: 1.0,
  );
}
```

**4. NotificationSettings**:
```dart
class NotificationSettings {
  final bool prayerNotificationsEnabled;
  final bool dailyAyahNotificationEnabled;
  final String dailyAyahTime;      // HH:mm format
  final bool beforePrayerReminder;
  final int reminderMinutes;       // Minutes before prayer
  
  static NotificationSettings defaultSettings() => NotificationSettings(
    prayerNotificationsEnabled: true,
    dailyAyahNotificationEnabled: true,
    dailyAyahTime: '08:00',
    beforePrayerReminder: true,
    reminderMinutes: 15,
  );
}
```

**5. AudioSettings**:
```dart
class AudioSettings {
  final String reciter;            // 'alafasy', 'abdulbasit', etc.
  final double volume;             // 0.0 - 1.0
  final double playbackSpeed;      // 0.5 - 2.0
  final bool enableAudioCache;
  final String audioQuality;       // 'low', 'medium', 'high'
  
  static AudioSettings defaultSettings() => AudioSettings(
    reciter: 'alafasy',
    volume: 0.8,
    playbackSpeed: 1.0,
    enableAudioCache: true,
    audioQuality: 'medium',
  );
}
```

**6. LocationSettings**:
```dart
class LocationSettings {
  final bool enableLocation;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final String calculationMethod;  // 'MWL', 'ISNA', 'Egypt', etc.
  
  static LocationSettings defaultSettings() => LocationSettings(
    enableLocation: false,
    calculationMethod: 'MWL',
  );
}
```

**Usage Example**:
```dart
// Create default preferences
UserPreferences prefs = UserPreferences.defaultSettings();

// Update specific setting
prefs = prefs.copyWith(
  theme: prefs.theme.copyWith(isDarkMode: true, fontScale: 1.2),
  reading: prefs.reading.copyWith(showTranslation: false),
);

// Access nested settings
print('Dark mode: ${prefs.theme.isDarkMode}');
print('Translation: ${prefs.reading.showTranslation}');
print('Reciter: ${prefs.audio.reciter}');

// Use in provider
class PreferenceProvider extends ChangeNotifier {
  UserPreferences _preferences = UserPreferences.defaultSettings();
  
  void updateTheme({bool? isDarkMode, double? fontScale}) {
    _preferences = _preferences.copyWith(
      theme: _preferences.theme.copyWith(
        isDarkMode: isDarkMode,
        fontScale: fontScale,
      ),
    );
    notifyListeners();
  }
}
```

---

## Entity Design Patterns

### Pattern 1: Value Objects (Immutability)
All entities are immutable with `const` constructors:
```dart
// ✅ Correct
const surah = Surah(number: 1, name: 'الفاتحة', ...);

// ❌ Wrong - no setters
surah.number = 2; // Compile error
```

### Pattern 2: Rich Business Logic
Entities contain domain rules, not just data:
```dart
// ✅ Correct - logic in entity
if (surah.isMeccan) { /* ... */ }

// ❌ Wrong - logic in UI/use case
if (surah.revelationType.toLowerCase() == 'meccan') { /* ... */ }
```

### Pattern 3: CopyWith for Updates
Immutable objects require copy-with pattern:
```dart
Verse updatedVerse = verse.copyWith(isBookmarked: true);
```

### Pattern 4: Factory Constructors for Defaults
```dart
UserPreferences prefs = UserPreferences.defaultSettings();
```

### Pattern 5: Equality & Hashing
Override for value equality:
```dart
@override
bool operator ==(Object other) =>
  identical(this, other) ||
  other is Surah && other.number == number;

@override
int get hashCode => number.hashCode;
```

---

## Testing Entities

### Test Immutability
```dart
test('surah should be immutable', () {
  final surah = Surah(number: 1, ...);
  // No way to modify - test passes by compilation
});
```

### Test Business Logic
```dart
test('should identify Meccan surah', () {
  final surah = Surah(revelationType: 'Meccan', ...);
  expect(surah.isMeccan, true);
  expect(surah.isMedinan, false);
});

test('should find next prayer correctly', () {
  final prayerTimes = PrayerTimes(
    fajr: DateTime(2025, 1, 15, 5, 30),
    dhuhr: DateTime(2025, 1, 15, 12, 15),
    // ...
  );
  
  final currentTime = DateTime(2025, 1, 15, 10, 0);
  final next = prayerTimes.getNextPrayer(currentTime);
  
  expect(next?.name, 'Dhuhr');
  expect(next?.time, DateTime(2025, 1, 15, 12, 15));
});
```

### Test Equality
```dart
test('surahs with same number should be equal', () {
  final surah1 = Surah(number: 1, name: 'A', ...);
  final surah2 = Surah(number: 1, name: 'B', ...);
  
  expect(surah1, equals(surah2)); // Equal by number
  expect(surah1.hashCode, equals(surah2.hashCode));
});
```

---

## Common Pitfalls

### ❌ Pitfall 1: Adding Framework Dependencies
```dart
// ❌ WRONG - Entity depends on Flutter
import 'package:flutter/material.dart';

class Surah {
  final Color themeColor; // NO! Color is from Flutter
}
```

**Solution**: Keep entities pure Dart. Move Flutter concerns to presentation layer.

### ❌ Pitfall 2: Mutable State
```dart
// ❌ WRONG
class Surah {
  int number;
  Surah(this.number);
}

// ✅ CORRECT
class Surah {
  final int number;
  const Surah({required this.number});
}
```

### ❌ Pitfall 3: Missing CopyWith
```dart
// ❌ WRONG - can't update immutable object
verse.isBookmarked = true;

// ✅ CORRECT
final updatedVerse = verse.copyWith(isBookmarked: true);
```

### ❌ Pitfall 4: Business Logic in Use Cases
```dart
// ❌ WRONG - logic should be in entity
class GetNextPrayerUseCase {
  Prayer? execute(PrayerTimes times) {
    // Complex prayer calculation logic here
  }
}

// ✅ CORRECT - logic in entity
final nextPrayer = prayerTimes.getNextPrayer();
```

---

**Related Documentation**:
- See `lib/domain/AGENTS.md` for domain layer overview
- See `lib/data/models/AGENTS.md` for data transfer objects
- See `lib/domain/usecases/AGENTS.md` for entity usage
