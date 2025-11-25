# Accessibility Audit Checklist - Salam Quran App

**Created**: November 16, 2025  
**Phase**: 5.2 - Accessibility Audit  
**Target**: WCAG 2.1 Level AA Compliance

## Overview

This document tracks accessibility compliance for the Salam Quran App to ensure it's usable by all Muslims, including those with disabilities.

---

## 1. Screen Reader Support

### 1.1 VoiceOver (iOS) Testing
- [ ] **Home Screen**
  - [ ] All buttons have clear labels
  - [ ] Recent reading card is accessible
  - [ ] Bottom navigation announces correctly
  - [ ] Surah cards announce: "Surah [name], [verses] verses, Meccan/Medinan"

- [ ] **Surah List Screen**
  - [ ] Search field has proper hint text
  - [ ] Filter buttons announce current state
  - [ ] Surah list items are focusable and descriptive
  - [ ] Scroll position announcements work

- [ ] **Surah Reader Screen**
  - [ ] Each verse is individually focusable
  - [ ] Verse numbers are announced
  - [ ] Translation toggle announces state
  - [ ] Audio controls are clearly labeled
  - [ ] Bookmark button announces state ("Bookmarked" / "Not bookmarked")

- [ ] **Mushaf Reader Screen**
  - [ ] Page images have semantic descriptions
  - [ ] Page navigation buttons work with VoiceOver
  - [ ] Current page number is announced
  - [ ] Juz markers are announced

- [ ] **Prayer Times Screen**
  - [ ] Each prayer time is announced with name and time
  - [ ] Next prayer countdown is accessible
  - [ ] Location toggle announces current location

- [ ] **Settings Screen**
  - [ ] All switches announce on/off state
  - [ ] Sliders announce current value
  - [ ] Dropdown menus are navigable
  - [ ] Save/Reset buttons are clearly labeled

### 1.2 TalkBack (Android) Testing
- [ ] Test all screens with TalkBack enabled
- [ ] Verify custom gestures work
- [ ] Check that announcements are clear and concise
- [ ] Test with different TalkBack verbosity levels

### 1.3 Semantic Labels Implementation

**Current Status**: ✅ Partially implemented in `accessibility_service.dart`

**Required Additions**:
```dart
// ✅ GOOD: Clear semantic label
Semantics(
  label: 'Surah Al-Fatiha, 7 verses, Meccan',
  button: true,
  onTap: _navigateToSurah,
  child: SurahCard(...),
)

// ❌ BAD: No semantic info
IconButton(
  icon: Icon(Icons.bookmark),
  onPressed: _toggleBookmark,
)

// ✅ GOOD: Descriptive label with state
Semantics(
  label: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
  button: true,
  child: IconButton(...),
)
```

**Files to Audit**:
- [ ] `surah_list.dart` - Surah cards need better labels
- [ ] `surah_reader.dart` - Verse tap areas need semantics
- [ ] `mushaf_reader.dart` - Page navigation buttons
- [ ] `prayer.dart` - Prayer time cards
- [ ] `qibla_screen.dart` - Compass direction announcements
- [ ] `settings_screen.dart` - All interactive elements

---

## 2. Keyboard Navigation

### 2.1 Tab Order
- [ ] Logical tab order (top to bottom, left to right)
- [ ] All interactive elements are focusable
- [ ] Skip to main content option available
- [ ] No keyboard traps

### 2.2 Focus Indicators
- [ ] Clear visual focus indicator on all elements
- [ ] Focus indicator meets 3:1 contrast ratio
- [ ] Focus follows navigation correctly
- [ ] Custom widgets have proper focus handling

### 2.3 Keyboard Shortcuts
**Planned Shortcuts** (macOS/web):
- [ ] `Cmd/Ctrl + F` - Search
- [ ] `Cmd/Ctrl + B` - Bookmarks
- [ ] `Space` - Play/Pause audio
- [ ] `Arrow Keys` - Navigate verses
- [ ] `Cmd/Ctrl + D` - Toggle dark mode
- [ ] `Esc` - Close dialogs/modals

**Implementation**:
```dart
// Add to relevant screens
Shortcuts(
  shortcuts: <ShortcutActivator, Intent>{
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): SearchIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      SearchIntent: CallbackAction<SearchIntent>(
        onInvoke: (SearchIntent intent) => _openSearch(),
      ),
    },
    child: MyWidget(),
  ),
)
```

---

## 3. Touch Target Sizes

### 3.1 Minimum Size Requirements
- **iOS**: 44x44 points minimum
- **Android**: 48x48 dp minimum
- **Web/Desktop**: 44x44 px minimum

### 3.2 Audit Results
- [ ] **Surah List**: Surah cards - ✅ Large enough
- [ ] **Surah Reader**: 
  - [ ] Bookmark button - Check size
  - [ ] Share button - Check size
  - [ ] Play button - Check size
  - [ ] Verse tap areas - Ensure full width
- [ ] **Bottom Navigation**: 
  - [ ] All nav items - Check size
  - [ ] Icon + label spacing
- [ ] **Settings**:
  - [ ] All switches - Check size
  - [ ] All buttons - Check size
- [ ] **Player Controls**:
  - [ ] Play/pause - Check size
  - [ ] Next/previous - Check size
  - [ ] Progress slider thumb - Ensure 44px min

### 3.3 Fix Template
```dart
// ❌ BAD: Too small
IconButton(
  iconSize: 20,
  padding: EdgeInsets.zero,
  icon: Icon(Icons.bookmark),
  onPressed: _bookmark,
)

// ✅ GOOD: Minimum 44x44
IconButton(
  iconSize: 24,
  padding: EdgeInsets.all(12), // 24 + 12*2 = 48
  icon: Icon(Icons.bookmark),
  onPressed: _bookmark,
  constraints: BoxConstraints(minWidth: 44, minHeight: 44),
)
```

---

## 4. Color Contrast

### 4.1 WCAG Requirements
- **Normal text** (< 18pt): 4.5:1 contrast ratio
- **Large text** (≥ 18pt or ≥ 14pt bold): 3:1 contrast ratio
- **UI components**: 3:1 contrast ratio

### 4.2 Contrast Audit (Light Mode)

**Text on Background**:
- [ ] Body text (#2C1810 on #FFFFFF) - Ratio: ___:1 - [ ] Pass
- [ ] Secondary text on background - Ratio: ___:1 - [ ] Pass
- [ ] Link text on background - Ratio: ___:1 - [ ] Pass

**Buttons**:
- [ ] Primary button text - Ratio: ___:1 - [ ] Pass
- [ ] Secondary button text - Ratio: ___:1 - [ ] Pass
- [ ] Icon buttons on background - Ratio: ___:1 - [ ] Pass

**Arabic Text** (Quran verses):
- [ ] Verse text (#000000 on #FAF8F3) - Ratio: ___:1 - [ ] Pass
- [ ] Verse numbers - Ratio: ___:1 - [ ] Pass

### 4.3 Contrast Audit (Dark Mode)

**Text on Background**:
- [ ] Body text on dark surface - Ratio: ___:1 - [ ] Pass
- [ ] Secondary text on dark - Ratio: ___:1 - [ ] Pass

**Buttons**:
- [ ] Primary button in dark mode - Ratio: ___:1 - [ ] Pass
- [ ] Icon buttons in dark mode - Ratio: ___:1 - [ ] Pass

**Arabic Text** (Quran verses):
- [ ] Verse text in dark mode - Ratio: ___:1 - [ ] Pass

### 4.4 Tools
- **Online**: [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- **macOS**: Digital Color Meter + manual calculation
- **Chrome**: DevTools Accessibility tab

### 4.5 Fixes Needed
```dart
// If contrast fails, adjust colors:
// Light mode body text
static const Color bodyText = Color(0xFF1A1A1A); // Darker for better contrast

// Dark mode body text  
static const Color bodyTextDark = Color(0xFFE8E8E8); // Lighter for better contrast

// Update in app_theme.dart
```

---

## 5. Text Scaling

### 5.1 Dynamic Type Support
- [ ] Test with 200% text scale (iOS Settings > Accessibility > Larger Text)
- [ ] Test with 300% text scale (Android Settings > Display > Font Size)
- [ ] Verify no text truncation
- [ ] Verify no layout breaks
- [ ] Verify scrollable content remains scrollable

### 5.2 Screens to Test
- [ ] **Home Screen** - Cards should expand vertically
- [ ] **Surah List** - List items should grow
- [ ] **Surah Reader** - Already has font size slider ✅
- [ ] **Settings** - Setting tiles should expand
- [ ] **Prayer Times** - Time display should scale
- [ ] **Bottom Navigation** - Labels should remain visible

### 5.3 Implementation Checks
```dart
// ✅ GOOD: Uses MediaQuery.textScaleFactor
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyMedium, // Respects system scale
)

// ❌ BAD: Fixed font size ignores system settings
Text(
  'Hello',
  style: TextStyle(fontSize: 16), // Fixed, doesn't scale
)

// ✅ GOOD: Max scale factor to prevent breaks
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaleFactor: min(MediaQuery.of(context).textScaleFactor, 2.0)),
  child: MyWidget(),
)
```

---

## 6. Motion & Animation

### 6.1 Reduce Motion Support
- [ ] Check iOS Settings > Accessibility > Motion > Reduce Motion
- [ ] Check Android Settings > Accessibility > Remove Animations
- [ ] Disable decorative animations when reduce motion is on
- [ ] Keep essential animations (loading indicators)

### 6.2 Implementation
```dart
// Check reduce motion preference
final accessibilityFeatures = MediaQuery.of(context).accessibilityFeatures;
final reduceMotion = accessibilityFeatures.reduceMotion;

// Conditionally apply animations
AnimatedOpacity(
  duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
  opacity: isVisible ? 1.0 : 0.0,
  child: child,
)
```

### 6.3 Files to Update
- [ ] `enhanced_animations.dart` - Add reduce motion checks
- [ ] `surah_reader.dart` - Verse highlight animation
- [ ] `main_screen.dart` - Page transition animations
- [ ] `onboarding_screen.dart` - Onboarding animations

---

## 7. Form Accessibility

### 7.1 Search Fields
- [ ] Search field has label: "Search Quran"
- [ ] Search field has hint text: "Search by surah name, number, or content"
- [ ] Clear button is accessible
- [ ] Search results are announced
- [ ] Error states are announced

### 7.2 Settings Forms
- [ ] All form fields have labels
- [ ] Required fields are marked
- [ ] Error messages are descriptive
- [ ] Success feedback is provided
- [ ] Form validation errors are accessible

---

## 8. Error Handling & Feedback

### 8.1 Error Messages
- [ ] Errors are announced to screen readers
- [ ] Error messages are descriptive
- [ ] Errors have sufficient color contrast
- [ ] Errors don't rely on color alone (use icons/text)

### 8.2 Success Feedback
- [ ] Success messages are announced
- [ ] "Bookmark added" - provides haptic + auditory feedback
- [ ] "Settings saved" - provides visual + auditory feedback

### 8.3 Loading States
- [ ] Loading indicators are announced: "Loading..."
- [ ] Progress indicators show % complete when possible
- [ ] Skeleton screens are semantically labeled

---

## 9. Internationalization (i18n) & Localization (l10n)

### 9.1 RTL Support (Arabic)
- [ ] Arabic text flows right-to-left ✅ (Already supported)
- [ ] UI elements flip for RTL (back buttons, etc.)
- [ ] Numbers display correctly in Arabic
- [ ] Quran verse numbers are in Arabic numerals

### 9.2 Screen Reader Languages
- [ ] VoiceOver/TalkBack respects app language
- [ ] Arabic content is read with Arabic pronunciation
- [ ] English content is read with English pronunciation

---

## 10. Platform-Specific Accessibility

### 10.1 iOS
- [ ] VoiceOver gestures work correctly
- [ ] Dynamic Type support ✅
- [ ] Voice Control support
- [ ] Switch Control support
- [ ] Accessibility Inspector passes all checks

### 10.2 Android
- [ ] TalkBack gestures work correctly
- [ ] Font scaling support ✅
- [ ] Select to Speak works
- [ ] Switch Access works
- [ ] Accessibility Scanner passes all checks

### 10.3 Web (if applicable)
- [ ] Keyboard navigation works
- [ ] ARIA labels are correct
- [ ] Focus management works
- [ ] Lighthouse accessibility score > 90

---

## Testing Tools

### Automated Testing
```bash
# Run accessibility tests
flutter test test/accessibility/

# iOS Accessibility Inspector
# Xcode > Open Developer Tool > Accessibility Inspector

# Android Accessibility Scanner
# Install from Play Store, scan app
```

### Manual Testing Checklist
1. [ ] Test with VoiceOver on (iOS Settings > Accessibility > VoiceOver)
2. [ ] Test with TalkBack on (Android Settings > Accessibility > TalkBack)
3. [ ] Test with 200% text scale
4. [ ] Test with Reduce Motion on
5. [ ] Test with high contrast mode
6. [ ] Test with grayscale display
7. [ ] Test keyboard-only navigation (iPad/Mac)
8. [ ] Test with external switch control

---

## Accessibility Checklist Summary

| Category | Items | Passing | Failing | Not Tested |
|----------|-------|---------|---------|------------|
| Screen Reader | 30 | 0 | 0 | 30 |
| Keyboard Nav | 10 | 0 | 0 | 10 |
| Touch Targets | 15 | 0 | 0 | 15 |
| Color Contrast | 20 | 0 | 0 | 20 |
| Text Scaling | 8 | 0 | 0 | 8 |
| Motion | 6 | 0 | 0 | 6 |
| Forms | 10 | 0 | 0 | 10 |
| Error Handling | 6 | 0 | 0 | 6 |
| i18n/l10n | 6 | 2 | 0 | 4 |
| Platform-Specific | 15 | 0 | 0 | 15 |
| **TOTAL** | **126** | **2** | **0** | **124** |

**Current Accessibility Score**: 1.6% Complete  
**Target**: 100% Complete by end of Phase 5

---

## Priority Fixes (High Impact)

1. **Add semantic labels to all interactive elements** (Screens: All)
2. **Verify touch target sizes** (Screens: All)
3. **Test color contrast in dark mode** (Screens: All)
4. **Implement reduce motion support** (`enhanced_animations.dart`)
5. **Add keyboard shortcuts** (Screens: Main, Surah Reader, Settings)

---

## Next Steps

1. Complete manual testing with VoiceOver/TalkBack
2. Run automated accessibility tests
3. Fix identified issues
4. Re-test after fixes
5. Document any remaining known issues
6. Update app description with accessibility features

---

**Last Updated**: November 16, 2025  
**Reviewed By**: _Pending_  
**Next Review**: After Phase 5.2 completion
