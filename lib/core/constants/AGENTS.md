# Core Constants - AGENTS.md

## Overview
This directory contains `app_constants.dart`, the single source of truth for all application-wide constants. **Never hardcode values** - always reference constants from this file.

## File: `app_constants.dart`

### Purpose
Centralized configuration for APIs, Quran data, cache settings, storage keys, and default values.

## Constant Categories

### 1. App Information
```dart
static const String appName = 'Quran App - القرآن الكريم';
static const String appVersion = '2.0.0';
static const String appDescription = 'A beautiful and comprehensive Quran reading app';
```

**Usage**: Display in about screen, app bar titles, metadata.

### 2. API Configuration
```dart
static const String quranApiBaseUrl = 'https://api.alquran.cloud/v1';
static const String prayerTimesApiBaseUrl = 'https://api.aladhan.com/v1';
static const String audioBaseUrl = 'https://cdn.islamic.network/quran/audio';
```

**Critical**: These are base URLs. Data sources append endpoints:
- Quran: `/surah`, `/surah/{number}`, `/surah/{surah}/{verse}`
- Prayer: `/timings/{timestamp}`, `/calendar/{year}/{month}`
- Audio: `/128/{reciter}/{surah}{verse:03d}.mp3`

### 3. Quran Data Constants
```dart
static const int totalSurahs = 114;     // Total chapters
static const int totalVerses = 6236;    // Total verses across all surahs
static const int totalPages = 604;      // Mushaf (book) pages
static const int totalParas = 30;       // Juz divisions
```

**Validation Use Cases**:
```dart
// Validate surah number
if (surahNumber < 1 || surahNumber > AppConstants.totalSurahs) {
  return ResultError(InvalidInputFailure(message: '...'));
}

// Check progress
double progress = currentVerse / AppConstants.totalVerses;
```

### 4. Cache Configuration
```dart
static const int maxCacheSize = 100; // MB
static const Duration cacheExpiry = Duration(days: 7);
static const Duration audioTokenExpiry = Duration(hours: 24);
```

**Usage in Models**:
```dart
bool get isExpired {
  final daysSinceCached = DateTime.now().difference(cachedAt).inDays;
  return daysSinceCached > AppConstants.cacheExpiry.inDays;
}
```

### 5. UI Configuration
```dart
static const double defaultArabicFontSize = 20.0;
static const double minArabicFontSize = 14.0;
static const double maxArabicFontSize = 32.0;
static const double defaultFontScale = 1.0;
static const double minFontScale = 0.7;
static const double maxFontScale = 2.0;
```

**Usage in Settings**:
```dart
// Slider constraints
Slider(
  value: fontSize,
  min: AppConstants.minArabicFontSize,
  max: AppConstants.maxArabicFontSize,
  onChanged: (value) => setState(() => fontSize = value),
)
```

### 6. Notification Configuration
```dart
static const int prayerNotificationId = 1001;
static const int dailyAyahNotificationId = 1002;
static const String notificationChannelId = 'quran_app_channel';
static const String notificationChannelName = 'Quran App Notifications';
```

**Critical**: Notification IDs must be unique. Use these in `PrayerNotificationService`.

### 7. Storage Keys (SharedPreferences)
```dart
static const String keyOnboardingCompleted = 'onboarding_completed';
static const String keyThemeMode = 'theme_mode';
static const String keyArabicFont = 'arabic_font';
static const String keySelectedReciter = 'selected_reciter';
static const String keyPreferredTranslation = 'preferred_translation';
static const String keyLastReadSurah = 'last_read_surah';
static const String keyLastReadVerse = 'last_read_verse';
```

**Naming Convention**: All keys prefixed with `key` to identify them as storage keys.

**Usage Pattern**:
```dart
final prefs = await SharedPreferences.getInstance();

// Save
await prefs.setBool(AppConstants.keyOnboardingCompleted, true);

// Load with default
final completed = prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
```

### 8. Default Values
```dart
static const String defaultReciter = 'ar.alafasy';
static const String defaultTranslation = 'en.sahih';
static const String defaultTafsir = 'en.jalalayn';
```

**Reciter Codes**:
- `ar.alafasy` - Mishary Alafasy (default, clear pronunciation)
- `ar.abdulbasit` - Abdul Basit Abdul Samad
- `ar.minshawi` - Mohamed Siddiq El-Minshawi
- `ar.husary` - Mahmoud Khalil Al-Hussary

**Translation Codes**:
- `en.sahih` - Sahih International (default, modern English)
- `en.pickthall` - Mohammed Marmaduke Pickthall
- `ar.muyassar` - المیسر (simplified Arabic tafsir)

## Adding New Constants

### Process
1. Identify the constant category (API, UI, Storage, etc.)
2. Add to appropriate section in `app_constants.dart`
3. Use descriptive naming with type prefix (e.g., `key` for storage keys)
4. Add inline comment if purpose isn't obvious
5. Update this AGENTS.md with usage examples

### Example: Adding a New Feature Setting
```dart
// In app_constants.dart
class AppConstants {
  // ... existing constants
  
  // Feature flags
  static const String keyEnableOfflineMode = 'enable_offline_mode';
  static const bool defaultOfflineMode = true;
}
```

### Example: Adding a New API Endpoint
```dart
// In app_constants.dart
static const String tafsirApiBaseUrl = 'https://api.quran-tafsir.com/v1';

// In data source
final url = '${AppConstants.tafsirApiBaseUrl}/tafsir/$surahNumber/$verseNumber';
```

## Common Patterns

### Pattern 1: Feature Toggle
```dart
// Constants
static const String keyEnableFeatureX = 'enable_feature_x';
static const bool defaultEnableFeatureX = false;

// Usage
final prefs = await SharedPreferences.getInstance();
final enabled = prefs.getBool(AppConstants.keyEnableFeatureX) 
  ?? AppConstants.defaultEnableFeatureX;

if (enabled) {
  // Feature logic
}
```

### Pattern 2: Range Validation
```dart
// Constants
static const double minValue = 0.5;
static const double maxValue = 2.0;

// Validation
double clampValue(double value) {
  return value.clamp(AppConstants.minValue, AppConstants.maxValue);
}
```

### Pattern 3: Multi-tenant Configuration (Future)
```dart
// If app needs different configurations per region
static const String apiBaseUrl = 
  environment == 'staging' 
    ? 'https://staging.api.alquran.cloud/v1'
    : 'https://api.alquran.cloud/v1';
```

## Hive Box Names
**Note**: Hive box names are NOT in this file (they're scattered in repository). Consider centralizing:

```dart
// Proposed addition to app_constants.dart
static const String hiveBoxSurahs = 'surahs';
static const String hiveBoxBookmarks = 'bookmarks';
static const String hiveBoxProgress = 'reading_progress';
static const String hiveBoxPrayerTimes = 'prayer_times';
static const String hiveBoxPageProgress = 'page_progress';
```

## Migration Notes

### If Moving to Environment Variables
Some constants (especially API URLs) might move to `.env`:
```env
QURAN_API_BASE_URL=https://api.alquran.cloud/v1
PRAYER_API_BASE_URL=https://api.aladhan.com/v1
```

Then in constants:
```dart
static final String quranApiBaseUrl = 
  dotenv.env['QURAN_API_BASE_URL'] ?? 'https://api.alquran.cloud/v1';
```

### If Adding Build Flavors (dev/staging/prod)
```dart
static String get quranApiBaseUrl {
  const flavor = String.fromEnvironment('FLAVOR');
  switch (flavor) {
    case 'dev': return 'https://dev.api.alquran.cloud/v1';
    case 'staging': return 'https://staging.api.alquran.cloud/v1';
    default: return 'https://api.alquran.cloud/v1';
  }
}
```

## Testing

### Mock Constants for Tests
```dart
// test/mocks/test_constants.dart
class TestConstants {
  static const String testApiBaseUrl = 'https://test.api.alquran.cloud/v1';
  static const int testTotalSurahs = 5; // Smaller for faster tests
}
```

---

**Related Documentation**:
- See `lib/core/AGENTS.md` for overall core layer structure
- See `lib/data/datasources/AGENTS.md` for API endpoint usage
- See `lib/presentation/providers/AGENTS.md` for storage key usage
