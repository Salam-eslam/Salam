# Accessibility Testing Guide - Quick Start

**Last Updated**: November 16, 2025  
**Status**: Phase 5.3 In Progress

## Overview

This guide provides step-by-step instructions for testing the Salam app's accessibility features. We're targeting **WCAG 2.1 Level AA** compliance.

---

## Quick Test Checklist ✅

### Priority 1: Screen Reader Testing (15 minutes)
- [ ] Enable VoiceOver/TalkBack
- [ ] Navigate through main screens
- [ ] Test all interactive elements
- [ ] Verify semantic labels are present

### Priority 2: Touch Targets (10 minutes)
- [ ] Verify all buttons are 44x44 minimum
- [ ] Test with large finger or stylus
- [ ] Check spacing between interactive elements

### Priority 3: Color Contrast (10 minutes)
- [ ] Test light mode contrast
- [ ] Test dark mode contrast
- [ ] Use contrast checker tool

### Priority 4: Text Scaling (5 minutes)
- [ ] Test with largest accessibility font size
- [ ] Verify no text truncation
- [ ] Check layout doesn't break

---

## iOS VoiceOver Testing

### 1. Enable VoiceOver
```
Settings → Accessibility → VoiceOver → ON
```

**Quick Toggle**: Triple-click side button (if configured)

### 2. Basic VoiceOver Gestures
- **Swipe Right**: Next element
- **Swipe Left**: Previous element
- **Double Tap**: Activate element
- **Three-Finger Swipe Up/Down**: Scroll

### 3. Test All Screens

**Main Screen (Home)**:
- [ ] Bottom navigation announces each tab correctly
- [ ] Theme toggle announces "Switch to dark mode" or "Switch to light mode"
- [ ] All tabs are reachable via swipe

**Surah List Screen**:
- [ ] Search field announces "Search by name, number, or Arabic"
- [ ] Clear button announces "Clear search"
- [ ] Each surah card announces: number, name, and type (Meccan/Medinan)
- [ ] Filter tabs announce correctly (All, Meccan, Medinan)

**Surah Reader Screen**:
- [ ] Play/pause button announces "Play audio" or "Pause audio"
- [ ] Bookmark button announces "Add bookmark"
- [ ] Settings button announces "Reading settings"
- [ ] Theme toggle announces mode switch
- [ ] Each verse is readable with proper Arabic pronunciation

**Mushaf Reader Screen**:
- [ ] Back button announces "رجوع" (Back in Arabic)
- [ ] Jump to page button announces "الانتقال إلى صفحة"
- [ ] Settings button announces "إعدادات القراءة"
- [ ] Page content is readable

**Bookmark Screen**:
- [ ] Search field has proper label
- [ ] Clear button announces "Clear search"
- [ ] Each bookmark card is accessible
- [ ] Delete actions are clear

**Settings Screen**:
- [ ] All settings sections are accessible
- [ ] Toggle switches announce state (on/off)
- [ ] Sliders announce current value

### 4. Common VoiceOver Issues to Check

❌ **Bad**: IconButton with no tooltip
```dart
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () {},
)
```

✅ **Good**: IconButton with tooltip
```dart
IconButton(
  icon: Icon(Icons.settings),
  tooltip: 'Reading settings',
  onPressed: () {},
)
```

❌ **Bad**: Decorative image with no semantic label
```dart
Image.asset('assets/icon.png')
```

✅ **Good**: Decorative image excluded from semantics
```dart
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/icon.png'),
)
```

---

## Android TalkBack Testing

### 1. Enable TalkBack
```
Settings → Accessibility → TalkBack → ON
```

### 2. Basic TalkBack Gestures
- **Swipe Right**: Next element
- **Swipe Left**: Previous element
- **Double Tap**: Activate element
- **Swipe Down then Right**: Read from top

### 3. Test Same Screens as iOS
Follow the same checklist as VoiceOver testing above. TalkBack should provide similar announcements.

---

## Touch Target Size Testing

### Minimum Size Requirements
- **iOS**: 44x44 points
- **Android**: 48x48 dp
- **We use**: 44x44 minimum for cross-platform consistency

### How to Test

1. **Visual Inspection**:
   ```dart
   // In code, look for:
   IconButton(icon: Icon(Icons.bookmark, size: 24)) // 48x48 default ✅
   GestureDetector(child: Container(width: 30, height: 30)) // ❌ Too small
   ```

2. **Manual Testing**:
   - Use your finger to tap all interactive elements
   - If you miss frequently, target is too small
   - Try with large finger or stylus

3. **Accessibility Inspector** (iOS):
   ```
   Xcode → Open Developer Tool → Accessibility Inspector
   Select device → Run inspection
   ```

4. **Layout Inspector** (Android):
   ```
   Android Studio → Tools → Layout Inspector
   Measure interactive elements
   ```

### Quick Fixes for Small Targets

❌ **Bad**: Small text button
```dart
TextButton(
  child: Text('Tap me'),
  onPressed: () {},
) // Default padding might be small
```

✅ **Good**: Adequate padding
```dart
TextButton(
  child: Padding(
    padding: EdgeInsets.all(12), // 44+ total size
    child: Text('Tap me'),
  ),
  onPressed: () {},
)
```

---

## Color Contrast Testing

### WCAG 2.1 AA Requirements
- **Normal text** (< 18pt): 4.5:1 contrast ratio
- **Large text** (≥ 18pt): 3:1 contrast ratio
- **UI components**: 3:1 contrast ratio

### Testing Tools

1. **WebAIM Contrast Checker** (Online):
   - URL: https://webaim.org/resources/contrastchecker/
   - Input foreground and background colors
   - Check pass/fail for AA/AAA

2. **Color Contrast Analyzer** (Desktop App):
   - Windows/Mac: https://www.tpgi.com/color-contrast-checker/
   - Eyedropper tool for picking colors

3. **Browser DevTools**:
   - Chrome DevTools → Elements → Computed → Contrast ratio

### How to Extract Colors from App

**Method 1: Code Review**
```dart
// Find color definitions
Text(
  'Hello',
  style: TextStyle(color: Colors.black87), // #DD000000
)
Container(color: Colors.white) // #FFFFFFFF
```

**Method 2: Screenshot + Color Picker**
- Take screenshot
- Open in Preview (Mac) or Paint (Windows)
- Use color picker tool
- Get hex values

### Test Both Modes

**Light Mode**:
- [ ] Text on surfaces
- [ ] Icons on backgrounds
- [ ] Buttons and interactive elements

**Dark Mode**:
- [ ] Text on surfaces (often lower contrast)
- [ ] Icons on dark backgrounds
- [ ] Gradient buttons maintain visibility

### Common Issues

❌ **Bad**: Low contrast
```dart
Text(
  'Subtle text',
  style: TextStyle(color: Colors.grey[400]), // on white: 2.8:1 ❌
)
```

✅ **Good**: Sufficient contrast
```dart
Text(
  'Clear text',
  style: TextStyle(color: Colors.grey[700]), // on white: 4.7:1 ✅
)
```

---

## Text Scaling Testing

### iOS Dynamic Type Testing

1. **Enable Large Text**:
   ```
   Settings → Accessibility → Display & Text Size → Larger Text
   → Drag slider to maximum
   ```

2. **Test All Screens**:
   - [ ] Text doesn't overflow containers
   - [ ] Buttons remain tappable
   - [ ] Layout adapts (no clipping)
   - [ ] Quran verses remain readable

### Android Font Size Testing

1. **Enable Large Font**:
   ```
   Settings → Accessibility → Font size → Drag to maximum
   ```

2. **Test Same as iOS**

### Code Support

Flutter's `MediaQuery.textScaleFactorOf()` should be respected:

✅ **Good**: Respects text scaling
```dart
Text('Scales properly') // Uses default text style
```

❌ **Bad**: Fixed size ignores scaling
```dart
Text('Ignores scaling', style: TextStyle(fontSize: 16)) // Might not scale
```

✅ **Better**: Scale-aware
```dart
Text(
  'Scales properly',
  style: Theme.of(context).textTheme.bodyLarge,
) // Uses theme, respects scaling
```

---

## Motion & Animation Testing

### Reduce Motion Support

**iOS**:
```
Settings → Accessibility → Motion → Reduce Motion → ON
```

**Android**:
```
Settings → Accessibility → Remove animations → ON
```

### Test Cases
- [ ] Animations are disabled or simplified
- [ ] Page transitions remain functional
- [ ] No content is hidden by disabled animations

### Code Implementation

Check if `AccessibilityService().initialize()` is called in `main()`:

```dart
// lib/services/accessibility_service.dart already handles this
class AccessibilityService {
  bool get reduceMotion => _reduceMotion;
}

// Usage in animations
AnimatedOpacity(
  duration: accessibilityService.reduceMotion 
    ? Duration.zero 
    : Duration(milliseconds: 300),
  // ...
)
```

---

## Keyboard Navigation Testing (Desktop)

### macOS
- [ ] Tab through all interactive elements
- [ ] Enter/Space activates focused element
- [ ] Escape closes dialogs
- [ ] Arrow keys navigate lists

### Windows
- [ ] Same as macOS

---

## Automated Testing

### Run Accessibility Scanner (Android)

1. Install from Play Store: "Accessibility Scanner"
2. Enable the service
3. Tap floating button while using app
4. Review suggestions

### Run Accessibility Inspector (iOS)

1. Xcode → Open Developer Tool → Accessibility Inspector
2. Select device
3. Run inspection
4. Fix reported issues

---

## Priority Fixes Based on Testing

### P0 (Critical - Block Release)
- [ ] All interactive elements have semantic labels
- [ ] Touch targets meet 44x44 minimum
- [ ] Critical text passes contrast (4.5:1)

### P1 (High - Fix Before Launch)
- [ ] VoiceOver navigation works smoothly
- [ ] Text scaling doesn't break layout
- [ ] Reduce motion is respected

### P2 (Medium - Fix Soon)
- [ ] All icons have tooltips
- [ ] Custom gestures have alternatives
- [ ] Error messages are announced

### P3 (Low - Nice to Have)
- [ ] Semantic grouping for related elements
- [ ] Custom focus order where needed
- [ ] Enhanced keyboard shortcuts

---

## Logging Issues

### Issue Template

**Title**: [Component] Accessibility Issue - [Description]

**Example**:
```
Title: [SurahReader] Missing tooltip on audio play button

Description:
- Location: lib/presentation/screens/surah_reader.dart:1154
- Issue: IconButton for audio control has no tooltip
- Impact: VoiceOver users don't know button purpose
- WCAG: 4.1.2 Name, Role, Value (Level A)

Fix:
IconButton(
  icon: Icon(Icons.play_circle_filled),
  tooltip: 'Play audio', // ← Add this
  onPressed: _playAudio,
)

Priority: P0 (blocking VoiceOver users)
```

---

## Testing Checklist Summary

| Category | Items | Tested | Pass | Fail |
|----------|-------|--------|------|------|
| Screen Reader | 30 | 0 | 0 | 0 |
| Touch Targets | 15 | 0 | 0 | 0 |
| Color Contrast | 20 | 0 | 0 | 0 |
| Text Scaling | 8 | 0 | 0 | 0 |
| Motion | 6 | 0 | 0 | 0 |
| Keyboard Nav | 10 | 0 | 0 | 0 |
| **TOTAL** | **89** | **0** | **0** | **0** |

**Target**: 100% pass before launch

---

## Next Steps

1. **Run VoiceOver Test** (30 min)
   - Test main flows
   - Document missing labels
   - Fix critical issues

2. **Touch Target Audit** (20 min)
   - Measure all interactive elements
   - Fix elements < 44x44

3. **Contrast Check** (20 min)
   - Test 10 most common screens
   - Fix failures < 4.5:1

4. **Quick Wins** (implemented):
   - ✅ Added tooltips to 8 IconButtons
   - ✅ Added RepaintBoundary to lists
   - 🔜 Add more semantic labels

5. **Full Audit** (2-3 days)
   - Complete 126-item checklist
   - Document all findings
   - Prioritize and fix issues

---

**Remember**: Accessibility is not optional. Making the app accessible to all users, including those with disabilities, is both legally required and morally right. Every fix improves someone's life.

---

**Related Documents**:
- `/docs/ACCESSIBILITY_AUDIT.md` - Complete 126-item checklist
- `/docs/PERFORMANCE_GUIDE.md` - Performance optimization strategies
- `/docs/PHASE_5_SUMMARY.md` - Phase 5 overview
