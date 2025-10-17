import 'package:flutter/foundation.dart';
import '../../domain/entities/quran_page_entity.dart';
import '../../domain/entities/surah_entity.dart';
import '../../data/datasources/quran_page_data.dart';
import '../../domain/repositories/quran_repository_interface.dart';

class QuranPageProvider with ChangeNotifier {
  final QuranRepositoryInterface _repository;

  QuranPageProvider(this._repository);

  Map<int, Surah> _loadedSurahs = {}; // Map of surah number to full surah with verses
  Map<int, QuranPage> _pagesCache = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => QuranPageData.totalPages;

  /// Initialize - no longer needs to load all surahs upfront
  Future<void> initialize() async {
    // Just a placeholder - surahs will be loaded on-demand
    _isLoading = false;
    notifyListeners();
  }

  /// Load a specific surah with all its verses
  Future<Surah?> _loadSurah(int surahNumber) async {
    // Check if already loaded
    if (_loadedSurahs.containsKey(surahNumber)) {
      return _loadedSurahs[surahNumber];
    }

    try {
      final result = await _repository.getSurah(surahNumber);

      switch (result) {
        case Success<Surah>():
          _loadedSurahs[surahNumber] = result.data;
          return result.data;
        case ResultError<Surah>():
          _error = result.failure.message;
          return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  /// Get page data for a specific page number
  Future<QuranPage?> getPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > QuranPageData.totalPages) {
      return null;
    }

    // Check cache first
    if (_pagesCache.containsKey(pageNumber)) {
      return _pagesCache[pageNumber];
    }

    // Build page from surah data (loads surahs on-demand)
    final pageData = await _buildPage(pageNumber);
    if (pageData != null) {
      _pagesCache[pageNumber] = pageData;
    }

    return pageData;
  }

  /// Build a page from the loaded surah data
  Future<QuranPage?> _buildPage(int pageNumber) async {
    final pageStart = QuranPageData.getPageStart(pageNumber);
    final pageEnd = QuranPageData.getPageStart(pageNumber + 1);

    if (pageStart == null) return null;

    final startSurah = pageStart[0];
    final startAyah = pageStart[1];

    // Basmallah text to filter out
    const basmallahText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ";

    List<PageAyah> pageAyahs = [];
    int currentSurahNum = startSurah;
    int currentAyahNum = startAyah;

    // Determine which surahs we need for this page
    Set<int> requiredSurahs = {startSurah};
    if (pageEnd != null && pageEnd[0] != startSurah) {
      // Page spans multiple surahs
      for (int i = startSurah; i < pageEnd[0]; i++) {
        requiredSurahs.add(i);
      }
    }

    // Load all required surahs
    for (int surahNum in requiredSurahs) {
      await _loadSurah(surahNum);
    }

    // Collect ayahs for this page
    while (true) {
      // Check if we've reached the next page
      if (pageEnd != null) {
        if (currentSurahNum > pageEnd[0] ||
            (currentSurahNum == pageEnd[0] && currentAyahNum >= pageEnd[1])) {
          break;
        }
      }

      // Get the surah (should be loaded now)
      final surah = _loadedSurahs[currentSurahNum];
      if (surah == null) {
        // Load it if missing
        await _loadSurah(currentSurahNum);
        final loadedSurah = _loadedSurahs[currentSurahNum];
        if (loadedSurah == null) {
          break; // Skip if we can't load it
        }
      }

      final surah2 = _loadedSurahs[currentSurahNum]!;

      // Check if ayah exists in surah
      if (currentAyahNum > surah2.numberOfAyahs) {
        // Move to next surah
        currentSurahNum++;
        currentAyahNum = 1;

        // Check if we've gone past all surahs
        if (currentSurahNum > 114) break;

        continue;
      }

      // Find the verse
      final verse = surah2.verses.firstWhere(
        (v) => v.number == currentAyahNum,
        orElse: () => Verse(
          number: currentAyahNum,
          arabicText: '',
        ),
      );

      // Skip empty verses and verses that are ONLY the Basmallah
      if (verse.arabicText.isNotEmpty &&
          verse.arabicText.trim() != basmallahText.trim()) {
        pageAyahs.add(PageAyah(
          surahNumber: currentSurahNum,
          surahName: surah2.englishName,
          surahNameArabic: surah2.name,
          ayahNumber: verse.number,
          text: verse.arabicText,
          numberInSurah: verse.number,
        ));
      }

      currentAyahNum++;
    }

    return QuranPage(
      pageNumber: pageNumber,
      juzNumber: QuranPageData.getJuzForPage(pageNumber),
      ayahs: pageAyahs,
    );
  }

  /// Preload pages around current page for smooth scrolling
  Future<void> preloadPages(int centerPage, {int range = 2}) async {
    final pagesToLoad = <int>[];

    for (int i = centerPage - range; i <= centerPage + range; i++) {
      if (i >= 1 && i <= QuranPageData.totalPages && !_pagesCache.containsKey(i)) {
        pagesToLoad.add(i);
      }
    }

    // Load pages in parallel
    await Future.wait(
      pagesToLoad.map((page) => getPage(page)),
    );
  }

  /// Set current page
  void setCurrentPage(int page) {
    if (page >= 1 && page <= QuranPageData.totalPages) {
      _currentPage = page;
      notifyListeners();

      // Preload surrounding pages
      preloadPages(page);
    }
  }

  /// Navigate to a specific surah and ayah
  int? findPageForAyah(int surahNumber, int ayahNumber) {
    // Binary search through pages to find the right one
    for (int page = 1; page <= QuranPageData.totalPages; page++) {
      final pageStart = QuranPageData.getPageStart(page);
      final pageEnd = QuranPageData.getPageStart(page + 1);

      if (pageStart == null) continue;

      final startSurah = pageStart[0];
      final startAyah = pageStart[1];

      // Check if this page contains the ayah
      if (surahNumber > startSurah ||
          (surahNumber == startSurah && ayahNumber >= startAyah)) {
        // Check if it's before the next page
        if (pageEnd == null ||
            surahNumber < pageEnd[0] ||
            (surahNumber == pageEnd[0] && ayahNumber < pageEnd[1])) {
          return page;
        }
      }
    }

    return null;
  }

  /// Clear cache to free memory
  void clearCache() {
    _pagesCache.clear();
    notifyListeners();
  }
}
