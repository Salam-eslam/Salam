# Performance Optimization Guide - Salam Quran App

**Created**: November 16, 2025  
**Status**: Phase 5 Implementation In Progress

## Current Performance Status

### ✅ Already Optimized
- **Const Constructors**: Most widgets use const constructors where applicable
- **Offline-First Architecture**: Three-tier caching strategy reduces network calls
- **Lazy Loading**: ListView.builder used in list screens
- **Widget Keys**: Proper use of keys for list items
- **System Fonts**: Removed Google Fonts to eliminate async loading errors

### 🚧 Performance Optimizations Implemented (Phase 5)

#### 1. Provider Optimization Strategy
**Goal**: Reduce unnecessary widget rebuilds

**Current State**:
- Many screens use `Consumer<T>` which rebuilds entire subtrees
- Some screens use `context.watch<T>()` causing full screen rebuilds

**Optimization Plan**:
```dart
// ❌ BEFORE: Rebuilds entire widget tree
Consumer<ThemeProvider>(
  builder: (context, theme, child) => Column(children: [...])
)

// ✅ AFTER: Only rebuilds when specific property changes
Selector<ThemeProvider, bool>(
  selector: (context, theme) => theme.isDarkMode,
  builder: (context, isDark, child) => Column(children: [...])
)
```

**Files to Optimize**:
- [x] `surah_list.dart` - Use Selector for theme/preferences
- [x] `surah_reader.dart` - Split providers into granular selectors  
- [x] `mushaf_reader.dart` - Optimize page state updates
- [x] `main_screen.dart` - Bottom nav shouldn't rebuild on theme changes
- [x] `settings_screen.dart` - Each setting tile should be isolated

#### 2. ListView Performance
**Goal**: Ensure smooth 60fps scrolling on all devices

**Current State**:
- `surah_list.dart` uses ListView.builder ✅
- `quran_page_widget.dart` builds complex layouts

**Optimizations**:
```dart
// Use RepaintBoundary for expensive widgets
ListView.builder(
  itemBuilder: (context, index) => RepaintBoundary(
    child: SurahCard(surah: surahs[index]),
  ),
)

// Cache extent for better scrolling
ListView.builder(
  cacheExtent: 500, // Preload 500px ahead
  itemBuilder: ...
)
```

**Implementation Status**:
- [x] Added RepaintBoundary to surah list cards
- [x] Optimized cache extent for long lists
- [ ] Profile with DevTools Performance tab

#### 3. Image & Asset Optimization
**Goal**: Reduce memory usage and load times

**Current State**:
- Icon assets exist in `assets/icon/`
- Font assets in `assets/fonts/`

**Actions**:
- [x] Verify all images are compressed
- [x] Use appropriate image resolutions (no 4K images for thumbnails)
- [ ] Add `CachedNetworkImage` for remote images (if any)
- [ ] Implement image cache size limits

#### 4. Animation Performance
**Goal**: Smooth animations without jank

**Current State**:
- `enhanced_animations.dart` has multiple animation widgets
- Page transitions use default Flutter animations

**Optimizations**:
```dart
// Use AnimatedBuilder instead of setState for animations
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * 2 * pi,
    child: child,
  ),
  child: const Icon(Icons.star), // Child is built once
)
```

**Files**:
- [x] `enhanced_animations.dart` - Already uses AnimatedBuilder ✅
- [ ] Check for expensive animations in `surah_reader.dart` (verse highlighting)
- [ ] Ensure animations < 300ms duration

#### 5. State Management Efficiency
**Goal**: Minimize notifyListeners() calls

**Current State**:
- Providers call notifyListeners() after every state change

**Best Practices**:
```dart
// ❌ BAD: Multiple notifyListeners
void updateSettings(Settings s) {
  _setting1 = s.value1;
  notifyListeners(); // rebuild 1
  _setting2 = s.value2;
  notifyListeners(); // rebuild 2
}

// ✅ GOOD: Batch updates
void updateSettings(Settings s) {
  _setting1 = s.value1;
  _setting2 = s.value2;
  notifyListeners(); // rebuild once
}
```

**Files to Review**:
- [ ] `surah_provider.dart` - Check loadSurah batching
- [ ] `enhanced_theme_provider.dart` - Theme changes are batched
- [ ] `bookmarks_provider.dart` - Batch bookmark operations

#### 6. Hive Database Optimization
**Goal**: Fast local data access

**Current Implementation**:
```dart
// ✅ GOOD: Using Hive lazy boxes for large data
await Hive.openLazyBox<CachedSurah>('surahs');

// ✅ GOOD: Proper indexing
// Surahs indexed by number (1-114)
_surahBox.get(surahNumber);
```

**Optimizations to Add**:
- [ ] Compact Hive boxes periodically (removes deleted entries)
- [ ] Add Hive TypeAdapters for better serialization performance
- [ ] Monitor box sizes (surah box, bookmarks box)
- [ ] Implement max cache size limits

#### 7. Memory Management
**Goal**: No memory leaks, efficient memory usage

**Checklist**:
- [x] Dispose AnimationControllers ✅
- [x] Dispose TextEditingControllers ✅
- [x] Dispose ScrollControllers ✅
- [ ] Profile with DevTools Memory tab
- [ ] Check for retained widget trees
- [ ] Verify image memory usage

## Performance Testing Checklist

### Manual Testing
- [ ] **Scroll Performance**: Scroll through surah list at high speed
  - Target: No jank, smooth 60fps
  - Test device: iPhone SE (low-end), iPhone 17 Pro (high-end)
  
- [ ] **Page Navigation**: Navigate between screens rapidly
  - Target: Transitions < 300ms
  - No lag on back button
  
- [ ] **Audio Playback**: Play Quran audio while scrolling
  - Target: No dropped frames
  - Audio continues smoothly during navigation
  
- [ ] **Search**: Type quickly in search field
  - Target: Results update < 100ms
  - No lag in text input

- [ ] **Theme Switching**: Change theme/dark mode
  - Target: Instant visual update
  - No flickering

### DevTools Profiling
- [ ] **Timeline View**: Record 10-second session
  - Check for red bars (dropped frames)
  - Identify expensive build methods
  - Verify < 16ms frame time (60fps)
  
- [ ] **Memory View**: Monitor during heavy use
  - Check for memory leaks (steadily increasing)
  - Verify GC cycles are reasonable
  - Image cache shouldn't exceed 100MB

- [ ] **Network View**: Monitor API calls
  - Verify caching is working (no duplicate calls)
  - Check for network waterfalls
  - API responses < 1 second

## Benchmark Results (To Be Filled)

### Before Optimizations
```
App Startup Time: ___ ms
Surah List Initial Load: ___ ms
Surah Reader Load: ___ ms
Search Query Response: ___ ms
Memory Usage (Idle): ___ MB
Memory Usage (Heavy): ___ MB
```

### After Phase 5 Optimizations
```
App Startup Time: ___ ms
Surah List Initial Load: ___ ms
Surah Reader Load: ___ ms
Search Query Response: ___ ms
Memory Usage (Idle): ___ MB
Memory Usage (Heavy): ___ MB
```

### Performance Targets
```
App Startup Time: < 2000ms
Surah List Initial Load: < 500ms
Surah Reader Load: < 300ms
Search Query Response: < 100ms
Memory Usage (Idle): < 100MB
Memory Usage (Heavy): < 250MB
Frame Rate: 60fps (16ms per frame)
```

## Common Performance Anti-Patterns to Avoid

### 1. Building Large Widgets in build()
```dart
// ❌ BAD
@override
Widget build(BuildContext context) {
  return Column(
    children: List.generate(1000, (i) => _buildComplexWidget(i)),
  );
}

// ✅ GOOD
@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: 1000,
    itemBuilder: (context, i) => _buildComplexWidget(i),
  );
}
```

### 2. Expensive Operations in build()
```dart
// ❌ BAD
@override
Widget build(BuildContext context) {
  final processedData = _expensiveComputation(rawData); // Called every rebuild!
  return Text(processedData);
}

// ✅ GOOD: Cache in initState or use memo
late final processedData = _expensiveComputation(rawData);
@override
Widget build(BuildContext context) {
  return Text(processedData);
}
```

### 3. Anonymous Functions as Widget Properties
```dart
// ❌ BAD: Creates new function every build
TextButton(
  onPressed: () => print('hello'),
  child: Text('Click'),
)

// ✅ GOOD: Use method reference
TextButton(
  onPressed: _handleClick,
  child: Text('Click'),
)

void _handleClick() => print('hello');
```

### 4. Not Using const Constructors
```dart
// ❌ BAD
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)

// ✅ GOOD
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

## Tools & Commands

### Flutter DevTools
```bash
# Run app in profile mode
flutter run --profile

# Open DevTools
dart devtools

# Analyze build performance
flutter run --profile --trace-skia
```

### Performance Analysis
```bash
# Check for performance lint warnings
flutter analyze

# Check bundle size
flutter build apk --analyze-size
flutter build ios --analyze-size

# Run performance tests
flutter test test/performance/
```

## Next Steps (Post Phase 5)

1. **Implement Performance Tests**
   - Create benchmark tests in `test/performance/`
   - Measure scroll performance
   - Measure build times
   - Track memory usage over time

2. **Set Up CI Performance Monitoring**
   - Run performance tests on every PR
   - Track metrics over time
   - Alert on regressions

3. **User Metrics**
   - Add Firebase Performance Monitoring
   - Track real-world performance data
   - Monitor crash-free sessions
   - Track app startup time

4. **Advanced Optimizations** (Phase 6+)
   - Implement code splitting
   - Add web workers (if web support added)
   - Optimize for low-end devices
   - Implement advanced caching strategies

---

**Last Updated**: November 16, 2025  
**Next Review**: After Phase 5 completion
