# Presentation Widgets - AGENTS.md

## Overview
Reusable UI components used across multiple screens. These are **stateless** or **stateful** widgets that don't manage app-level state (providers do).

## Files

### 1. `enhanced_animations.dart`
**Purpose**: Custom animations for smooth UI transitions.

**Exports**:
- `FadeInAnimation` - Fade in with optional delay
- `SlideInAnimation` - Slide from direction (top/bottom/left/right)
- `ScaleAnimation` - Scale up/down with bounce
- `RotateAnimation` - Rotate with configurable duration
- `ShimmerAnimation` - Loading shimmer effect

**Usage**:
```dart
FadeInAnimation(
  delay: Duration(milliseconds: 200),
  child: Text('بِسْمِ اللَّهِ'),
)
```

---

### 2. `enhanced_loading.dart`
**Purpose**: Loading indicators and skeletons.

**Widgets**:
- `CircularLoadingIndicator` - Themed spinner
- `LinearLoadingBar` - Progress bar
- `ShimmerSkeleton` - Skeleton loader for list items
- `PulsingDot` - Typing indicator (for AI chat)

**Usage**:
```dart
if (isLoading) {
  return CircularLoadingIndicator(message: 'Loading surah...');
}
```

---

### 3. `quran_page_widget.dart`
**Purpose**: Displays a single Mushaf page with verse highlighting.

**Props**:
```dart
QuranPageWidget({
  required QuranPage page,
  double fontSize = 18.0,
  Color highlightColor = Colors.amber,
  Function(int surahNumber, int verseNumber)? onVerseTap,
  bool showVerseNumbers = true,
})
```

**Features**:
- Renders Arabic text with proper line breaks
- Highlights selected verse
- Tappable verses for bookmarks/audio
- Adjustable font size
- Bismillah display for surah starts

**Usage**:
```dart
QuranPageWidget(
  page: currentPage,
  fontSize: 20.0,
  onVerseTap: (surah, verse) {
    showVerseActions(surah, verse);
  },
)
```

---

### 4. `recent_reading_widget.dart`
**Purpose**: Displays user's recent reading history on home screen.

**Props**:
```dart
RecentReadingWidget({
  required List<ReadingProgress> recentSurahs,
  Function(int surahNumber)? onSurahTap,
})
```

**Shows**:
- Last 5 read surahs
- Arabic name + English translation
- Last read timestamp
- Continue reading button

**Usage**:
```dart
RecentReadingWidget(
  recentSurahs: provider.recentReadings,
  onSurahTap: (surahNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(surahNumber: surahNumber),
      ),
    );
  },
)
```

---

## Common Widget Patterns

### Pattern 1: Reusable Card
```dart
class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${surah.number}')),
        title: Text(surah.name),
        subtitle: Text('${surah.numberOfAyahs} verses'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
```

### Pattern 2: Theme-Aware Widget
```dart
class ThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

### Pattern 3: Loading State Widget
```dart
class DataListWidget<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<T> data;
  final Widget Function(T item) builder;
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CircularLoadingIndicator();
    }
    
    if (error != null) {
      return ErrorWidget(error!);
    }
    
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) => builder(data[index]),
    );
  }
}
```

---

## Testing Widgets

```dart
testWidgets('should display surah name', (tester) async {
  final surah = Surah(number: 1, name: 'الفاتحة', ...);
  
  await tester.pumpWidget(
    MaterialApp(
      home: SurahCard(surah: surah, onTap: () {}),
    ),
  );
  
  expect(find.text('الفاتحة'), findsOneWidget);
  expect(find.text('7 verses'), findsOneWidget);
});
```

---

**Related Documentation**:
- See `lib/presentation/AGENTS.md` for presentation overview
- See `lib/presentation/screens/AGENTS.md` for widget usage
- See `lib/core/utils/AGENTS.md` for app theme
