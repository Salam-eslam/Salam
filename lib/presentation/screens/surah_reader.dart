import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../domain/entities/surah_entity.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/surah_provider.dart';
import '../providers/enhanced_theme_provider.dart';
import '../providers/translation_provider.dart';
import '../providers/tafsir_provider.dart';
import '../providers/reading_stats_provider.dart';

import '../../data/models/translation.dart';
import '../../data/models/tafsir.dart';
import '../../services/audio_player_service.dart';

import 'package:scroll_to_index/scroll_to_index.dart';

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? highlightAyah; // Optional parameter for highlighting
  const SurahReaderScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    this.highlightAyah,
  }) : super(key: key);
  @override
  _SurahReaderScreenState createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  List<Verse> _ayahs = [];
  TranslationSet? _translations;
  TafsirSet? _tafsir;
  bool _isLoading = true;
  bool _isError = false;
  static const String basmallahImagePath = 'assets/basmallah.png';
  late AudioPlayerService _audioPlayerService;
  int? _currentlyPlayingAyah;
  double? _originalBrightness;
  late AutoScrollController _scrollController;
  int _totalAyahs = 0;
  int _lastReportedAyah =
      0; // Track last reported ayah to avoid excessive updates

  // Stats tracking
  Timer? _readingTimer;
  int _secondsSpent = 0;
  final Set<int> _readVerses = {};

  // Provider references (saved to avoid context access in dispose)
  ReadingStatsProvider? _statsProvider;

  // Audio subscription
  StreamSubscription? _audioCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = AudioPlayerService();
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    );
    _initializeBrightness();

    // Start reading timer
    _startReadingTimer();

    // Listen to audio completion
    _audioCompleteSubscription = _audioPlayerService.onComplete.listen((_) {
      if (mounted && _currentlyPlayingAyah != null) {
        _playNextAyah();
      }
    });

    // Load surah data after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSurah();
      _loadTranslations();
      _loadTafsir();
    });

    // Set up scroll listener for progress tracking
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save provider reference early to use in dispose
    _statsProvider ??= context.read<ReadingStatsProvider>();
  }

  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsSpent++;
        });
      }
    });
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _audioCompleteSubscription?.cancel();
    _saveReadingSession();
    _restoreBrightness();
    _audioPlayerService.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _restoreBrightness() {
    if (_originalBrightness != null) {
      try {
        ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } catch (e) {
        logger.warning('Failed to restore brightness: $e');
      }
    }
  }

  void _saveReadingSession() {
    if (_secondsSpent > 0 || _readVerses.isNotEmpty) {
      try {
        // Use saved provider reference instead of context
        _statsProvider?.addSession(
          _readVerses.length,
          _secondsSpent,
        );
      } catch (e) {
        logger.error('Error saving reading session: $e');
      }
    }
  }

  void _playNextAyah() {
    if (_currentlyPlayingAyah == null) return;

    // Find current index in _ayahs
    int currentIndex =
        _ayahs.indexWhere((v) => v.number == _currentlyPlayingAyah);
    if (currentIndex != -1 && currentIndex < _ayahs.length - 1) {
      // Play next verse in the list
      _playAudio(_ayahs[currentIndex + 1].number);
    } else {
      _stopAudio();
    }
  }

  Future<void> _scrollToAyah(int ayahNumber) async {
    int index = -1;
    for (int i = 0; i < _ayahs.length; i++) {
      if (_ayahs[i].number == ayahNumber) {
        index = i + 1; // +1 for Basmallah
        break;
      }
    }

    if (index != -1) {
      await _scrollController.scrollToIndex(
        index,
        preferPosition: AutoScrollPosition.begin,
      );
    }
  }

  Future<void> _loadSurah() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final surahProvider = context.read<SurahProvider>();
      final success = await surahProvider.loadSurah(widget.surahNumber);

      if (!mounted) return;

      if (success) {
        final surah = surahProvider.getSurahByNumber(widget.surahNumber);

        if (surah != null && surah.verses.isNotEmpty) {
          final filteredVerses = surah.verses.where((verse) {
            final normalizedText = normalizeText(verse.arabicText);
            return !normalizedText.contains('بِسْمِ ٱللَّهِ');
          }).toList();

          setState(() {
            _ayahs = filteredVerses;
            _totalAyahs = surah.numberOfAyahs;
            _isLoading = false;
          });

          // Handle initial highlight if provided
          if (widget.highlightAyah != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToAyah(widget.highlightAyah!);
            });
          }
        } else {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      } else {
        // Check if there's an error message from the provider
        final errorMessage = surahProvider.errorMessage;
        setState(() {
          _isError = true;
          _isLoading = false;
        });

        if (mounted && errorMessage != null) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      logger.error('Error loading surah ${widget.surahNumber}: $e');

      if (!mounted) return;

      setState(() {
        _isError = true;
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load surah. Please check your connection.');
    }
  }

  String normalizeText(String input) {
    final diacritics = RegExp(r'[\u064B-\u0652]');
    return input
        .replaceAll(diacritics, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _playAudio(int ayahNumber) async {
    if (!mounted) return;

    String surahStr = widget.surahNumber.toString().padLeft(3, '0');
    String ayahStr = ayahNumber.toString().padLeft(3, '0');
    String audioUrl =
        'https://everyayah.com/data/AbdulSamad_64kbps_QuranExplorer.Com/$surahStr$ayahStr.mp3';

    try {
      await _audioPlayerService.play(audioUrl);
      if (!mounted) return;

      setState(() {
        _currentlyPlayingAyah = ayahNumber;
      });
      _scrollToAyah(ayahNumber);

      // Update reading progress
      if (mounted) {
        _readVerses.add(ayahNumber);
        context.read<ReadingProgressProvider>().updateProgress(
              widget.surahNumber,
              widget.surahName,
              ayahNumber,
              _totalAyahs,
            );
      }
    } catch (e) {
      logger.error('Error playing audio for ayah $ayahNumber: $e');
      if (mounted) {
        _showErrorSnackBar('Unable to play audio. Please try again.');
      }
    }
  }

  void _stopAudio() async {
    try {
      await _audioPlayerService.stop();
      setState(() {
        _currentlyPlayingAyah = null;
      });
    } catch (e) {
      logger.error('Error stopping audio: $e');
      _showErrorSnackBar('Error stopping audio.');
    }
  }

  void _showBookmarkDialog(Verse verse) {
    final noteController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.bookmark_add,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Bookmark',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Save this verse for later',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verse preview card
              Card(
                elevation: 0,
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.surahName} ${verse.number}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.arabicText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Quran',
                          fontSize: 18,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      if (verse.translation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          verse.translation!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note input
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Add a personal note (optional)',
                  hintText: 'Why is this verse meaningful to you?',
                  prefixIcon: const Icon(Icons.note_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final success =
                            await context.read<BookmarksProvider>().addBookmark(
                                  surahNumber: widget.surahNumber,
                                  verseNumber: verse.number,
                                  note: noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim(),
                                );

                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccessSnackBar(
                            success
                                ? 'Bookmark saved successfully!'
                                : 'Failed to save bookmark',
                            isSuccess: success,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.bookmark_add, size: 20),
                      label: const Text('Save Bookmark'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
    } catch (e) {
      logger.warning('Failed to get current brightness: $e');
      // Fallback to default brightness if unable to get current
      _originalBrightness = 0.5;
    }
  }

  void _onScroll() {
    if (!mounted || _ayahs.isEmpty) return;

    final progressProvider =
        Provider.of<ReadingProgressProvider>(context, listen: false);

    // Get the current scroll position
    final scrollOffset = _scrollController.offset;
    final totalScrollableHeight = _scrollController.position.maxScrollExtent;

    // Calculate progress as percentage of scroll completion
    double scrollProgress = 0.0;
    if (totalScrollableHeight > 0) {
      scrollProgress = (scrollOffset / totalScrollableHeight).clamp(0.0, 1.0);
    }

    // If user has scrolled to the very bottom, mark as completed
    if (scrollOffset >= totalScrollableHeight - 10) {
      // 10px threshold for bottom detection
      // Mark as fully completed - this will trigger auto-removal in the provider
      if (_lastReportedAyah != _totalAyahs) {
        _lastReportedAyah = _totalAyahs;
        progressProvider.updateProgress(
          widget.surahNumber,
          widget.surahName,
          _totalAyahs, // Set to total ayahs to indicate completion
          _totalAyahs,
        );
      }
      return;
    }

    // Convert scroll progress to ayah number
    // Calculate which ayah corresponds to the current scroll position
    // Use ceiling to ensure we show the ayah we're currently viewing
    final currentAyah =
        (scrollProgress * _totalAyahs).ceil().clamp(1, _totalAyahs);

    // Only update if the ayah has changed and is valid
    if (currentAyah > 0 &&
        currentAyah <= _totalAyahs &&
        currentAyah != _lastReportedAyah) {
      _lastReportedAyah = currentAyah;
      progressProvider.updateProgress(
        widget.surahNumber,
        widget.surahName,
        currentAyah,
        _totalAyahs,
      );
    }
  }

  Future<void> _loadTranslations() async {
    final prefProvider =
        Provider.of<PreferenceSettingsProvider>(context, listen: false);
    if (!prefProvider.showTranslation) return;

    try {
      final translationProvider = context.read<TranslationProvider>();
      final success = await translationProvider.loadSurahTranslations(
        widget.surahNumber,
        prefProvider.selectedTranslation,
      );

      if (success && mounted) {
        final translations = translationProvider.surahTranslations;
        if (translations != null) {
          setState(() {
            _translations = TranslationSet(
              translations: translations
                  .asMap()
                  .entries
                  .map((entry) => Translation(
                        number: entry.key + 1,
                        text: entry.value,
                        edition: prefProvider.selectedTranslation,
                        language: 'en',
                      ))
                  .toList(),
              surahName: widget.surahName,
              surahNumber: widget.surahNumber,
            );
          });
        }
      }
    } catch (e) {
      logger.warning(
          'Error loading translations for surah ${widget.surahNumber}: $e');
      // Don't show error to user as translations are optional
    }
  }

  Future<void> _loadTafsir() async {
    final prefProvider =
        Provider.of<PreferenceSettingsProvider>(context, listen: false);
    if (!prefProvider.showTafsir) {
      // Clear tafsir when disabled
      if (mounted) {
        setState(() {
          _tafsir = null;
        });
      }
      return;
    }

    try {
      logger.debug(
          '📖 Loading tafsir for surah ${widget.surahNumber} with edition: ${prefProvider.selectedTafsir}');

      final tafsirProvider = context.read<TafsirProvider>();
      final tafasirList = <Tafsir>[];

      // Load tafsir for each verse in the surah
      for (int i = 1; i <= _totalAyahs; i++) {
        final tafsirText = await tafsirProvider.loadVerseTafsir(
          widget.surahNumber,
          i,
          prefProvider.selectedTafsir,
        );

        if (tafsirText != null && tafsirText.isNotEmpty) {
          tafasirList.add(Tafsir(
            ayahNumber: i,
            text: tafsirText,
            author: prefProvider.selectedTafsir,
            language:
                prefProvider.selectedTafsir.startsWith('ar') ? 'ar' : 'en',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _tafsir = TafsirSet(
            tafasir: tafasirList,
            surahName: widget.surahName,
            surahNumber: widget.surahNumber,
          );
        });

        logger.info('✅ Tafsir loaded: ${tafasirList.length} entries');
      }
    } catch (e) {
      logger
          .error('❌ Error loading tafsir for surah ${widget.surahNumber}: $e');

      // Set empty tafsir to show "not available" message
      if (mounted) {
        setState(() {
          _tafsir = TafsirSet(
            tafasir: [],
            surahName: widget.surahName,
            surahNumber: widget.surahNumber,
          );
        });
      }
    }
  }

  /// Helper method to show error messages to users
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Helper method to show success messages to users
  void _showSuccessSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBeautifulSelector({
    required String currentValue,
    required Map<String, String> options,
    required Function(String) onSelected,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Select Option',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                // Options List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final entry = options.entries.elementAt(index);
                      final isSelected = entry.value == currentValue;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? color.withValues(alpha: 0.5)
                                : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            onSelected(entry.key);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? color : Colors.grey,
                                      width: 2,
                                    ),
                                    color:
                                        isSelected ? color : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentValue,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingControls() {
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.tune,
                          color: theme.colorScheme.onPrimary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Reading Settings',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Font Size Control
                      Selector<EnhancedThemeProvider, double>(
                        selector: (context, themeProvider) =>
                            themeProvider.arabicFontSize,
                        builder: (context, fontSize, child) {
                          final themeProvider =
                              context.read<EnhancedThemeProvider>();
                          return _buildSettingsCard(
                            icon: Icons.format_size,
                            title: 'Font Size',
                            subtitle: '${fontSize.round()}px',
                            child: Slider(
                              value: fontSize,
                              min: 14.0,
                              max: 32.0,
                              divisions: 18,
                              onChanged: (value) {
                                themeProvider.setArabicFontSize(value);
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Reading Mode Selection
                      _buildSettingsCard(
                        icon: Icons.nightlight_round,
                        title: 'Reading Mode',
                        subtitle: 'Choose your preferred reading experience',
                        child: Selector<EnhancedThemeProvider, ReadingMode>(
                          selector: (context, themeProvider) =>
                              themeProvider.readingMode,
                          builder: (context, readingMode, child) {
                            final themeProvider =
                                context.read<EnhancedThemeProvider>();
                            return RadioGroup<ReadingMode>(
                              groupValue: readingMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setReadingMode(value);
                                  if (value == ReadingMode.night) {
                                    if (_originalBrightness != null) {
                                      ScreenBrightness()
                                          .setScreenBrightness(0.3);
                                    }
                                  } else {
                                    if (_originalBrightness != null) {
                                      ScreenBrightness().setScreenBrightness(
                                          _originalBrightness!);
                                    }
                                  }
                                }
                              },
                              child: Column(
                                children: [
                                  RadioListTile<ReadingMode>(
                                    title: const Text('Normal'),
                                    subtitle:
                                        const Text('Regular reading mode'),
                                    value: ReadingMode.normal,
                                  ),
                                  RadioListTile<ReadingMode>(
                                    title: const Text('Night Reading'),
                                    subtitle: const Text(
                                        'Dark theme with dimmed screen'),
                                    value: ReadingMode.night,
                                  ),
                                  RadioListTile<ReadingMode>(
                                    title: const Text('Comfort Reading'),
                                    subtitle: const Text(
                                        'Warm colors for extended reading'),
                                    value: ReadingMode.comfort,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Translation Section
                      Selector<PreferenceSettingsProvider, bool>(
                        selector: (context, prefProvider) =>
                            prefProvider.showTranslation,
                        builder: (context, showTranslation, child) {
                          final prefProvider =
                              context.read<PreferenceSettingsProvider>();
                          return _buildSettingsCard(
                            icon: Icons.translate,
                            title: 'Translation',
                            subtitle: showTranslation ? 'Enabled' : 'Disabled',
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: showTranslation,
                                  onChanged: (value) async {
                                    prefProvider.toggleTranslation(value);
                                    if (value) {
                                      await _loadTranslations();
                                    } else {
                                      setState(() {
                                        _translations = null;
                                      });
                                    }
                                  },
                                  title: const Text('Show Translation'),
                                ),
                                if (prefProvider.showTranslation) ...[
                                  const SizedBox(height: 12),
                                  _buildBeautifulSelector(
                                    currentValue: PreferenceSettingsProvider
                                                .availableTranslations[
                                            prefProvider.selectedTranslation] ??
                                        'Select Translation',
                                    options: PreferenceSettingsProvider
                                        .availableTranslations,
                                    onSelected: (key) async {
                                      prefProvider.setSelectedTranslation(key);
                                      await _loadTranslations();
                                    },
                                    icon: Icons.translate,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tafsir Section
                      Selector<PreferenceSettingsProvider,
                          ({bool showTafsir, String selectedTafsir})>(
                        selector: (_, prefProvider) => (
                          showTafsir: prefProvider.showTafsir,
                          selectedTafsir: prefProvider.selectedTafsir
                        ),
                        builder: (context, data, child) {
                          final prefProvider =
                              context.read<PreferenceSettingsProvider>();
                          return _buildSettingsCard(
                            icon: Icons.menu_book,
                            title: 'Tafsir (Commentary)',
                            subtitle: data.showTafsir ? 'Enabled' : 'Disabled',
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: data.showTafsir,
                                  onChanged: (value) async {
                                    prefProvider.toggleTafsir(value);
                                    if (value) {
                                      await _loadTafsir();
                                    } else {
                                      setState(() {
                                        _tafsir = null;
                                      });
                                    }
                                  },
                                  title: const Text('Show Commentary'),
                                ),
                                if (data.showTafsir) ...[
                                  const SizedBox(height: 12),
                                  _buildBeautifulSelector(
                                    currentValue: PreferenceSettingsProvider
                                                .availableTafsir[
                                            data.selectedTafsir] ??
                                        'Select Tafsir',
                                    options: PreferenceSettingsProvider
                                        .availableTafsir,
                                    onSelected: (key) async {
                                      prefProvider.setSelectedTafsir(key);
                                      await _loadTafsir();
                                    },
                                    icon: Icons.menu_book,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.secondary;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAyahWidget(
      Verse verse, int index, PreferenceSettingsProvider prefProvider) {
    final theme = Theme.of(context);
    final isHighlighted =
        widget.highlightAyah != null && verse.number == widget.highlightAyah;
    final isPlaying = _currentlyPlayingAyah == verse.number;

    // Get translation for this ayah
    Translation? translation;
    if (_translations != null) {
      try {
        translation = _translations!.translations.firstWhere(
          (t) => t.number == verse.number,
        );
      } catch (e) {
        // Translation not found
      }
    }

    // Get tafsir for this ayah
    Tafsir? tafsir;
    if (_tafsir != null) {
      try {
        tafsir = _tafsir!.tafasir.firstWhere(
          (t) => t.ayahNumber == verse.number,
        );
      } catch (e) {
        // Tafsir not found
      }
    }

    return AutoScrollTag(
      key: ValueKey(index),
      controller: _scrollController,
      index: index,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        elevation: isHighlighted ? 8.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: isHighlighted
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Elegant Header with Ayah Number
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  // Beautiful Ayah Number
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPlaying
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        verse.number.toString(),
                        style: TextStyle(
                          color: isPlaying
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Action Buttons with Beautiful Styling
                  Row(
                    children: [
                      // Audio Control
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: isPlaying
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          size: 28,
                        ),
                        tooltip: isPlaying ? 'Pause audio' : 'Play audio',
                        onPressed: () {
                          if (isPlaying) {
                            _stopAudio();
                          } else {
                            _playAudio(verse.number);
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      // Bookmark Button
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_add_rounded,
                          color: theme.colorScheme.secondary,
                          size: 24,
                        ),
                        tooltip: 'Add bookmark',
                        onPressed: () => _showBookmarkDialog(verse),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Decorative Divider
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor,
            ),

            // Arabic Text with Beautiful Typography
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Selector<EnhancedThemeProvider, double>(
                    selector: (_, themeProvider) =>
                        themeProvider.arabicFontSize,
                    builder: (context, arabicFontSize, child) {
                      final themeProvider =
                          context.read<EnhancedThemeProvider>();
                      return Text(
                        verse.arabicText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily:
                              'Roboto', // This should be a specific quran font if available
                          fontSize: arabicFontSize,
                          height: 2.0,
                          color: themeProvider.getReadingModeTextColor(context),
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),

                  // Decorative ornament
                  if (!prefProvider.showTranslation && !prefProvider.showTafsir)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      width: 80,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            theme.dividerColor,
                            Colors.transparent
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),

            // Translation with Beautiful Styling
            if (prefProvider.showTranslation && translation != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 14,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Translation',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          translation.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tafsir with Beautiful Styling
            if (prefProvider.showTafsir)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 14,
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Commentary',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Show tafsir text if available, otherwise show helpful message
                        if (tafsir != null && tafsir.text.isNotEmpty)
                          Text(
                            tafsir.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        else
                          Text(
                            'Tafsir not available for this verse.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ReadingProgressProvider>(context);
    final themeProvider = Provider.of<EnhancedThemeProvider>(context);
    final progress = progressProvider.getProgress(widget.surahNumber);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: themeProvider.getReadingModeBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: TextStyle(
            color: themeProvider.getReadingModeTextColor(context),
          ),
        ),
        backgroundColor: themeProvider.getReadingModeBackgroundColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: themeProvider.getReadingModeTextColor(context),
        ),
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Reading settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildReadingControls(),
                isScrollControlled: true,
              );
            },
          ),
          // Theme Toggle
          IconButton(
            icon: Icon(
              themeProvider.isDarkTheme(context)
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: themeProvider.isDarkTheme(context)
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () {
              themeProvider.setThemeMode(
                themeProvider.isDarkTheme(context)
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? Center(
                  child: Text(
                    'Failed to load ayahs. Please try again later.',
                    style: TextStyle(
                      color: themeProvider.getReadingModeTextColor(context),
                      fontSize: 16.0,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Reading Progress Indicator
                    if (progress != null)
                      Selector<EnhancedThemeProvider, Color>(
                        selector: (context, themeProvider) =>
                            themeProvider.getReadingModeCardColor(context),
                        builder: (context, cardColor, child) {
                          return Container(
                            margin: const EdgeInsets.all(16.0),
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      theme.shadowColor.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.bookmark,
                                    color: theme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Continue Reading',
                                        style: TextStyle(
                                          color: themeProvider
                                              .getReadingModeTextColor(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last read: Ayah ${progress.lastReadAyah}',
                                        style: TextStyle(
                                          color: themeProvider
                                              .getReadingModeTextColor(context)
                                              .withValues(alpha: 0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${progress.progressPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 60,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            progress.progressPercentage / 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Content
                    Expanded(
                      child: Consumer<PreferenceSettingsProvider>(
                        builder: (context, prefProvider, child) {
                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: _ayahs.length + 1, // +1 for Basmallah
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Selector<EnhancedThemeProvider, bool>(
                                  selector: (context, themeProvider) =>
                                      themeProvider.isDarkTheme(context),
                                  builder: (context, isDarkTheme, child) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ColorFiltered(
                                        colorFilter: isDarkTheme
                                            ? const ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.multiply)
                                            : const ColorFilter.matrix([
                                                -1,
                                                0,
                                                0,
                                                0,
                                                255,
                                                0,
                                                -1,
                                                0,
                                                0,
                                                255,
                                                0,
                                                0,
                                                -1,
                                                0,
                                                255,
                                                0,
                                                0,
                                                0,
                                                1,
                                                0,
                                              ]),
                                        child: Image.asset(
                                          basmallahImagePath,
                                          height: 50.0,
                                          fit: BoxFit.contain,
                                          color: themeProvider
                                              .getReadingModeTextColor(context),
                                          colorBlendMode: BlendMode.modulate,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              final verse = _ayahs[index - 1];
                              return _buildAyahWidget(
                                  verse, index - 1, prefProvider);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
