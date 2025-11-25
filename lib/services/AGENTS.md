# Services Layer - AGENTS.md

## Overview
The `services` layer contains **external integrations** and **cross-cutting concerns** that don't fit cleanly into data/domain/presentation. These are typically singleton services or static utility classes.

## Directory Structure
```
services/
├── islamic_ai_service.dart           # GPT-4 OpenAI integration
├── prayer_notification_service.dart  # Local notifications for prayers
├── accessibility_service.dart        # TTS and accessibility features
├── audio_player_service.dart         # Quran audio playback
├── auto_cache_service.dart           # Background caching
├── community_service.dart            # Social features
├── islamic_calendar_service.dart     # Hijri calendar
├── qibla_service.dart               # Qibla direction finder
└── quran_service.dart               # Quran-specific utilities
```

## Key Services

### 1. Islamic AI Service (GPT-4)

**File**: `islamic_ai_service.dart`

```dart
class IslamicAIService {
  static const String _systemPrompt = '''
  You are an Islamic knowledge assistant...
  ONLY answer questions related to Quran, Hadith, Fiqh, Islamic history...
  If question is NOT Islamic, say "I don't have sufficient knowledge..."
  ''';
  
  IslamicAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in .env');
    }
    OpenAI.apiKey = apiKey;
  }
  
  Future<AIResponse> askQuestion(String question) async {
    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4.1-mini-2025-04-14",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt)],
            role: OpenAIChatMessageRole.system,
          ),
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(question)],
            role: OpenAIChatMessageRole.user,
          ),
        ],
        temperature: 0.3, // Low temperature for focused responses
        maxTokens: 500,
      );
      
      final response = chatCompletion.choices.first.message.content?.first.text ?? '';
      return AIResponse(
        answer: response,
        isFromCache: false,
      );
    } catch (e) {
      throw Exception('AI service error: $e');
    }
  }
}

class AIResponse {
  final String answer;
  final bool isFromCache;
  
  AIResponse({required this.answer, required this.isFromCache});
}
```

**Critical Features**:
- **Constrained AI**: System prompt enforces Islamic topics only
- **No overrides**: User cannot bypass system prompt (security measure)
- **Temperature 0.3**: Lower = more focused/deterministic responses
- **Max tokens 500**: Limits response length
- **GPT-4 Mini**: Cost-effective model for this use case

**Usage in UI**:
```dart
final aiService = IslamicAIService();
final response = await aiService.askQuestion('What is Zakat?');
print(response.answer);
```

**Environment Setup**:
```env
# .env
OPENAI_API_KEY=sk-...
```

### 2. Prayer Notification Service

**File**: `prayer_notification_service.dart`

```dart
class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
    FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  /// Initialize notification plugin
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _notifications.initialize(InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    ));
    
    await _requestPermissions();
    _isInitialized = true;
  }
  
  /// Schedule notifications for all 5 prayers
  static Future<void> scheduleAllPrayerNotifications(
    CachedPrayerTimes prayerTimes
  ) async {
    await initialize();
    await cancelAllNotifications();
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('prayer_notifications_enabled') ?? true;
    final reminderMinutes = prefs.getInt('prayer_reminder_minutes') ?? 10;
    
    if (!enabled) return;
    
    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'time': prayerTimes.isha},
    ];
    
    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final prayerTime = DateTime.parse(prayer['time'] as String);
      final reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
      
      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: i * 2,
          title: '🕌 ${prayer['name']} Prayer Reminder',
          body: '${prayer['name']} prayer time is in $reminderMinutes minutes',
          scheduledTime: reminderTime,
        );
        
        await _scheduleNotification(
          id: i * 2 + 1,
          title: '🕌 ${prayer['name']} Prayer Time',
          body: 'It\'s time for ${prayer['name']} prayer',
          scheduledTime: prayerTime,
        );
      }
    }
  }
  
  /// Schedule daily ayah notification
  static Future<void> scheduleDailyAyahNotification() async {
    await initialize();
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_ayah_enabled') ?? true;
    
    if (!enabled) return;
    
    // Schedule for 9 AM daily
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }
    
    await _scheduleNotification(
      id: 1002,
      title: '📖 Daily Ayah',
      body: 'Read your verse of the day',
      scheduledTime: scheduledTime,
      isRecurring: true,
    );
  }
  
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
```

**Key Features**:
- **5 daily prayers**: Fajr, Dhuhr, Asr, Maghrib, Isha
- **Reminder notifications**: X minutes before prayer (configurable)
- **Daily ayah**: Scheduled notification at 9 AM
- **Timezone support**: Uses `timezone` package for accurate scheduling
- **Permission handling**: Requests notification permissions on init

**Usage**:
```dart
// In main() or settings screen
await PrayerNotificationService.initialize();
await PrayerNotificationService.scheduleAllPrayerNotifications(prayerTimes);
await PrayerNotificationService.scheduleDailyAyahNotification();
```

### 3. Accessibility Service

**File**: `accessibility_service.dart`

```dart
class AccessibilityService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _isInitialized = true;
  }
  
  /// Speak Arabic text
  Future<void> speakArabic(String text) async {
    await initialize();
    await _tts.setLanguage('ar');
    await _tts.speak(text);
  }
  
  /// Speak English text
  Future<void> speakEnglish(String text) async {
    await initialize();
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }
  
  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
  }
  
  /// Check if currently speaking
  Future<bool> isSpeaking() async {
    return await _tts.getState() == TtsState.playing;
  }
}
```

**Features**:
- **Multi-language TTS**: Arabic and English support
- **Configurable**: Speech rate, volume, pitch
- **State management**: Check if currently speaking

**Usage**:
```dart
final accessibility = AccessibilityService();
await accessibility.initialize();
await accessibility.speakArabic('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
```

### 4. Audio Player Service

**File**: `audio_player_service.dart`

```dart
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentReciter;
  int? _currentSurah;
  int? _currentVerse;
  
  /// Play verse audio
  Future<void> playVerse(int surah, int verse, String reciter) async {
    final url = _buildAudioUrl(surah, verse, reciter);
    
    await _player.play(UrlSource(url));
    
    _currentSurah = surah;
    _currentVerse = verse;
    _currentReciter = reciter;
  }
  
  /// Play entire surah
  Future<void> playSurah(int surah, String reciter) async {
    final url = _buildSurahAudioUrl(surah, reciter);
    await _player.play(UrlSource(url));
  }
  
  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();
  Future<void> stop() async => await _player.stop();
  
  String _buildAudioUrl(int surah, int verse, String reciter) {
    final surahStr = surah.toString().padLeft(3, '0');
    final verseStr = verse.toString().padLeft(3, '0');
    return '${AppConstants.audioBaseUrl}/128/$reciter/$surahStr$verseStr.mp3';
  }
  
  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  
  void dispose() {
    _player.dispose();
  }
}
```

**Audio URL Format**:
```
https://cdn.islamic.network/quran/audio/128/{reciter}/{surah}{verse}.mp3
Example: .../128/ar.alafasy/001001.mp3 (Surah 1, Verse 1)
```

**Available Reciters**:
- `ar.alafasy` - Mishary Alafasy
- `ar.abdulbasit` - Abdul Basit
- `ar.minshawi` - Mohamed Siddiq El-Minshawi
- `ar.husary` - Mahmoud Khalil Al-Hussary

### 5. Auto Cache Service

**File**: `auto_cache_service.dart`

```dart
class AutoCacheService {
  static const String _baseUrl = 'http://api.alquran.cloud/v1';
  
  /// Cache common surahs for offline access
  static Future<void> cacheCommonSurahs() async {
    final commonSurahs = [1, 2, 18, 36, 55, 67, 112, 113, 114];
    // Al-Fatiha, Al-Baqarah, Al-Kahf, Ya-Sin, Ar-Rahman, Al-Mulk, 
    // Al-Ikhlas, Al-Falaq, An-Nas
    
    for (final surahNumber in commonSurahs) {
      try {
        await getSurah(surahNumber);
      } catch (e) {
        // Skip on error, continue caching others
      }
    }
  }
  
  /// Get surah with automatic permanent caching
  static Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_surah_$surahNumber';
    
    // Check cache first
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return Map<String, dynamic>.from(json.decode(cachedData));
    }
    
    // Fetch from API
    final response = await http.get(
      Uri.parse('$_baseUrl/surah/$surahNumber/quran-uthmani'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final surahData = data['data'];
        
        // Cache permanently
        await prefs.setString(cacheKey, json.encode(surahData));
        
        return Map<String, dynamic>.from(surahData);
      }
    }
    
    throw Exception('Failed to load surah');
  }
  
  /// Clear all cached surahs
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cached_surah_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
```

**Usage** (called in main()):
```dart
void _initializeCache() {
  Future.delayed(Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}
```

### 6. Qibla Service

**File**: `qibla_service.dart`

```dart
class QiblaService {
  final FlutterQiblah _qiblah = FlutterQiblah();
  
  /// Get Qibla direction stream
  Stream<QiblahDirection> get qiblahStream => _qiblah.qiblahStream;
  
  /// Check if device supports Qibla (has compass)
  Future<bool> isSupported() async {
    return await FlutterQiblah.androidDeviceSensorSupport() ?? false;
  }
  
  /// Calculate Qibla direction from coordinates
  double calculateQiblaDirection(double latitude, double longitude) {
    const kabaLat = 21.4225;
    const kabaLng = 39.8262;
    
    final lat1 = _toRadians(latitude);
    final lng1 = _toRadians(longitude);
    final lat2 = _toRadians(kabaLat);
    final lng2 = _toRadians(kabaLng);
    
    final dLng = lng2 - lng1;
    
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    
    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }
  
  double _toRadians(double degrees) => degrees * pi / 180;
  double _toDegrees(double radians) => radians * 180 / pi;
}
```

## Service Initialization

### In main()
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CachedSurahAdapter());
  // ... register other adapters
  
  // Initialize DI
  await DependencyInjection.init();
  
  // Initialize auto cache (background)
  _initializeCache();
  
  // Initialize services (delayed)
  _initializeServices();
  
  runApp(MyApp());
}

void _initializeCache() {
  Future.delayed(Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}

void _initializeServices() {
  Future.delayed(Duration(seconds: 3), () async {
    try {
      await PrayerNotificationService.initialize();
      await PrayerNotificationService.scheduleDailyAyahNotification();
      await AccessibilityService().initialize();
    } catch (e) {
      // Log error but don't crash app
    }
  });
}
```

## Service Patterns

### Pattern 1: Singleton Service
```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    // ... initialization
    _isInitialized = true;
  }
  
  Future<void> doSomething() async {
    await initialize();
    // ... logic
  }
}
```

### Pattern 2: Static Utility Class
```dart
class MyUtility {
  MyUtility._(); // Private constructor, prevent instantiation
  
  static Future<void> doSomething() async {
    // ... logic
  }
  
  static String formatData(String data) {
    // ... logic
    return formattedData;
  }
}
```

### Pattern 3: Service with Dependencies
```dart
class MyService {
  final ApiClient _api;
  final Storage _storage;
  
  MyService({
    required ApiClient api,
    required Storage storage,
  }) : _api = api, _storage = storage;
  
  Future<void> doSomething() async {
    final data = await _api.fetchData();
    await _storage.save(data);
  }
}
```

## Common Gotchas

### ❌ Don't: Forget to initialize services
```dart
// Will crash if not initialized
await PrayerNotificationService.scheduleAllPrayerNotifications(...);
```

### ✅ Do: Initialize before use
```dart
await PrayerNotificationService.initialize();
await PrayerNotificationService.scheduleAllPrayerNotifications(...);
```

### ❌ Don't: Block main thread with heavy operations
```dart
void main() async {
  AutoCacheService.cacheCommonSurahs(); // Blocks app start
  runApp(MyApp());
}
```

### ✅ Do: Defer heavy operations
```dart
void main() async {
  runApp(MyApp());
  
  // Cache in background after 2 seconds
  Future.delayed(Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}
```

### ❌ Don't: Forget error handling
```dart
final response = await aiService.askQuestion(query); // Can throw
```

### ✅ Do: Handle errors gracefully
```dart
try {
  final response = await aiService.askQuestion(query);
  // Use response
} catch (e) {
  // Show error to user
  showError('AI service error: $e');
}
```

## Required Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for prayer times</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for audio features</string>
```

---

**Related Documentation**:
- See `/AGENTS.md` for overall architecture
- See `lib/presentation/AGENTS.md` for using services in UI
- See `lib/data/AGENTS.md` for data layer services integration
