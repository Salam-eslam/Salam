# Data Models - AGENTS.md

## Overview
Models are data transfer objects for serialization/caching. Split into two categories:
1. **Hive Models** (with `@HiveType`): For local caching, require code generation
2. **Plain Models**: For JSON serialization only

**Key Differences from Entities**:
- Models: Include serialization logic (`fromJson`, `toJson`, Hive adapters)
- Entities: Pure business objects, no serialization

## Hive Models (Require Code Generation)

### Running Code Generation
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 1. `cached_surah.dart` + `cached_surah.g.dart`
**Purpose**: Cache Surah data locally for offline access.

```dart
@HiveType(typeId: 0)
class CachedSurah extends HiveObject {
  @HiveField(0) final int number;
  @HiveField(1) final String name;
  @HiveField(2) final String englishName;
  @HiveField(3) final String revelationType;
  @HiveField(4) final int numberOfAyahs;
  @HiveField(5) final List<CachedAyah> ayahs;
  @HiveField(6) final DateTime cachedAt;
  
  bool get isExpired => DateTime.now().difference(cachedAt).inDays > 30;
}

@HiveType(typeId: 1)
class CachedAyah extends HiveObject {
  @HiveField(0) final int number;
  @HiveField(1) final String text;
  @HiveField(2) final int numberInSurah;
}
```

**Register Adapter**:
```dart
Hive.registerAdapter(CachedSurahAdapter());
Hive.registerAdapter(CachedAyahAdapter());
```

---

### 2. `bookmark.dart` + `bookmark.g.dart`
**Purpose**: Store user bookmarks with optional notes.

```dart
@HiveType(typeId: 2)
class Bookmark extends HiveObject {
  @HiveField(0) final int surahNumber;
  @HiveField(1) final String surahName;
  @HiveField(2) final int ayahNumber;
  @HiveField(3) final String text;
  @HiveField(4) final String? note;
  @HiveField(5) final DateTime createdAt;
}
```

---

### 3. `cached_prayer_times.dart` + `cached_prayer_times.g.dart`
**Purpose**: Cache daily prayer times to avoid repeated API calls.

```dart
@HiveType(typeId: 3)
class CachedPrayerTimes extends HiveObject {
  @HiveField(0) final DateTime date;
  @HiveField(1) final DateTime fajr;
  @HiveField(2) final DateTime sunrise;
  @HiveField(3) final DateTime dhuhr;
  @HiveField(4) final DateTime asr;
  @HiveField(5) final DateTime maghrib;
  @HiveField(6) final DateTime isha;
  @HiveField(7) final double latitude;
  @HiveField(8) final double longitude;
  
  bool get isToday => date.day == DateTime.now().day;
}
```

---

### 4. `page_progress.dart` + `page_progress.g.dart`
**Purpose**: Track which Mushaf pages user has read.

```dart
@HiveType(typeId: 4)
class PageProgress extends HiveObject {
  @HiveField(0) final int pageNumber;
  @HiveField(1) final bool isCompleted;
  @HiveField(2) final DateTime lastReadAt;
}
```

---

### 5. `reading_progress.dart`
**Purpose**: Store user's last reading position.

```dart
@HiveType(typeId: 5)
class ReadingProgress extends HiveObject {
  @HiveField(0) final int surahNumber;
  @HiveField(1) final int ayahNumber;
  @HiveField(2) final int pageNumber;
  @HiveField(3) final DateTime lastReadAt;
}
```

---

### 6. `cached_audio.dart` + `cached_audio.g.dart`
**Purpose**: Cache audio metadata and URLs.

```dart
@HiveType(typeId: 6)
class CachedAudio extends HiveObject {
  @HiveField(0) final int surahNumber;
  @HiveField(1) final String reciterKey;
  @HiveField(2) final String audioUrl;
  @HiveField(3) final DateTime cachedAt;
  
  bool get isExpired => DateTime.now().difference(cachedAt).inDays > 7;
}
```

---

## Plain Models (JSON Only)

### 7. `translation.dart`
**Purpose**: Translation data from API.

```dart
class Translation {
  final int number;       // Verse number
  final String text;      // Translated text
  final String edition;   // Translator name
  final String language;  // 'en', 'ur', 'id', etc.
  
  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      edition: json['edition']?['name'] ?? '',
      language: json['edition']?['language'] ?? '',
    );
  }
}
```

---

### 8. `tafsir.dart`
**Purpose**: Tafsir (commentary) data from API.

```dart
class Tafsir {
  final int ayahNumber;
  final String text;
  final String source;    // 'ar.muyassar', 'en.kathir', etc.
  
  factory Tafsir.fromJson(Map<String, dynamic> json) {
    return Tafsir(
      ayahNumber: json['ayahNumber'] ?? 0,
      text: json['text'] ?? '',
      source: json['source'] ?? '',
    );
  }
}
```

---

## Model Patterns

### Pattern 1: Entity ↔ Model Conversion
```dart
// Repository converts between models and entities
CachedSurah _convertEntityToModel(Surah entity) {
  return CachedSurah(
    number: entity.number,
    name: entity.name,
    // ... map all fields
    cachedAt: DateTime.now(),
  );
}

Surah _convertModelToEntity(CachedSurah model) {
  return Surah(
    number: model.number,
    name: model.name,
    verses: model.ayahs.map((a) => Verse(...)).toList(),
  );
}
```

### Pattern 2: Hive Type IDs
Each Hive model needs **unique** `typeId`:
```dart
@HiveType(typeId: 0)  // CachedSurah
@HiveType(typeId: 1)  // CachedAyah
@HiveType(typeId: 2)  // Bookmark
// Never reuse typeId even after deleting model!
```

### Pattern 3: Cache Expiration
```dart
class CachedSurah {
  final DateTime cachedAt;
  
  bool get isExpired {
    final age = DateTime.now().difference(cachedAt);
    return age.inDays > 30; // 30 day TTL
  }
}
```

---

## Adding New Hive Model

**Step 1**: Create model with annotations
```dart
import 'package:hive/hive.dart';
part 'my_model.g.dart';

@HiveType(typeId: 7) // Next available ID
class MyModel extends HiveObject {
  @HiveField(0) final String field1;
  @HiveField(1) final int field2;
  
  MyModel({required this.field1, required this.field2});
}
```

**Step 2**: Run code generation
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Step 3**: Register adapter in `main()`
```dart
void main() async {
  Hive.registerAdapter(MyModelAdapter());
  // ...
}
```

**Step 4**: Open box in repository
```dart
class MyRepository {
  late Box<MyModel> _myBox;
  
  Future<void> initialize() async {
    _myBox = await Hive.openBox<MyModel>('my_data');
  }
}
```

---

## Common Pitfalls

### ❌ Pitfall 1: Forgetting Code Generation
```dart
@HiveType(typeId: 0)
class MyModel { /* ... */ }
// Build fails! Must run build_runner
```

**Solution**: Run `flutter packages pub run build_runner build`

### ❌ Pitfall 2: Reusing Type IDs
```dart
@HiveType(typeId: 0) // Used by CachedSurah!
class MyModel { /* ... */ }
```

**Solution**: Use next available ID (check all existing models)

### ❌ Pitfall 3: Not Registering Adapter
```dart
// Forgot to register in main()
Hive.openBox<MyModel>('box'); // Runtime error!
```

**Solution**: `Hive.registerAdapter(MyModelAdapter())` in `main()`

### ❌ Pitfall 4: Missing `.g.dart` Part
```dart
@HiveType(typeId: 0)
class MyModel { /* ... */ }
// Missing: part 'my_model.g.dart';
```

---

**Related Documentation**:
- See `lib/data/AGENTS.md` for data layer overview
- See `lib/domain/entities/AGENTS.md` for entity structure
- See `lib/data/repositories/AGENTS.md` for model usage
