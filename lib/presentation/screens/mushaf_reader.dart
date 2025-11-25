import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_page_provider.dart';
import '../providers/enhanced_theme_provider.dart';
import '../providers/page_progress_provider.dart';
import '../widgets/quran_page_widget.dart';
import '../../domain/entities/quran_page_entity.dart';

class MushafReader extends StatefulWidget {
  final int initialPage;

  const MushafReader({
    Key? key,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _isLoading = true;
  final Map<int, QuranPage> _loadedPages = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(
      initialPage: widget.initialPage - 1,
      viewportFraction: 0.95,
    );

    // Schedule initialization after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReader();
    });
  }

  Future<void> _initializeReader() async {
    final provider = context.read<QuranPageProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the provider
      await provider.initialize();

      // Load initial page and surrounding pages
      await _loadPage(_currentPage);
      await provider.preloadPages(_currentPage, range: 3);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading Quran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPage(int pageNumber) async {
    if (_loadedPages.containsKey(pageNumber)) return;

    final provider = context.read<QuranPageProvider>();
    final page = await provider.getPage(pageNumber);

    if (page != null && mounted) {
      setState(() {
        _loadedPages[pageNumber] = page;
      });
    }
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1;

    setState(() {
      _currentPage = pageNumber;
    });

    // Update provider
    context.read<QuranPageProvider>().setCurrentPage(pageNumber);

    // Track progress
    context.read<PageProgressProvider>().updateProgress(pageNumber);

    // Load current page and surrounding pages
    _loadPage(pageNumber);
    _loadPage(pageNumber - 1);
    _loadPage(pageNumber + 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<EnhancedThemeProvider, ReadingMode>(
      selector: (context, themeProvider) => themeProvider.readingMode,
      builder: (context, readingMode, _) {
        final themeProvider = context.read<EnhancedThemeProvider>();
        final colors = _getThemeColors(themeProvider);

        return Scaffold(
          backgroundColor: colors['background'],
          appBar: _buildAppBar(colors),
          body: _isLoading
              ? _buildLoadingView(colors)
              : _buildPageView(colors, themeProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, Color> colors) {
    return AppBar(
      backgroundColor: colors['surface']?.withValues(alpha: 0.95),
      elevation: 0,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories,
                color: colors['primary'],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'المصحف الشريف',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors['text'],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Selector<PageProgressProvider, int>(
            selector: (context, progressProvider) => _currentPage,
            builder: (context, currentPage, _) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors['primary']!.withValues(alpha: 0.15),
                      colors['primary']!.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'صفحة $_currentPage من 604',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors['text']?.withValues(alpha: 0.7),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors['primary']?.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: colors['primary'], size: 20),
          tooltip: 'رجوع',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: colors['text']?.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.search, color: colors['text'], size: 22),
            onPressed: _showJumpToPageDialog,
            tooltip: 'الانتقال إلى صفحة',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: colors['text']?.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: colors['text'], size: 22),
            onPressed: _showSettingsBottomSheet,
            tooltip: 'إعدادات القراءة',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView(Map<String, Color> colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors['primary'],
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المصحف...',
            style: TextStyle(
              fontSize: 16,
              color: colors['text']?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(
      Map<String, Color> colors, EnhancedThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors['background']!,
            colors['background']!.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: 604,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final page = _loadedPages[pageNumber];

          if (page == null) {
            // Show loading placeholder with animation
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colors['primary'],
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'جاري تحميل الصفحة...',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors['text']?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: QuranPageWidget(
                page: page,
                backgroundColor: colors['surface']!,
                textColor: colors['text']!,
                fontSize: themeProvider.arabicFontSize,
              ),
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element

  void _showJumpToPageDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('الانتقال إلى صفحة'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم الصفحة (1-604)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final pageNumber = int.tryParse(controller.text);
                if (pageNumber != null &&
                    pageNumber >= 1 &&
                    pageNumber <= 604) {
                  Navigator.pop(context);
                  _pageController.animateToPage(
                    pageNumber - 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<EnhancedThemeProvider>(
          builder: (context, themeProvider, _) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات القراءة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font size
                  const Text('حجم الخط'),
                  Slider(
                    value: themeProvider.arabicFontSize,
                    min: 16,
                    max: 32,
                    divisions: 16,
                    label: themeProvider.arabicFontSize.round().toString(),
                    onChanged: (value) {
                      themeProvider.setArabicFontSize(value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Reading mode
                  const Text('وضع القراءة'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('عادي'),
                        selected:
                            themeProvider.readingMode == ReadingMode.normal,
                        onSelected: (_) =>
                            themeProvider.setReadingMode(ReadingMode.normal),
                      ),
                      ChoiceChip(
                        label: const Text('ليلي'),
                        selected:
                            themeProvider.readingMode == ReadingMode.night,
                        onSelected: (_) =>
                            themeProvider.setReadingMode(ReadingMode.night),
                      ),
                      ChoiceChip(
                        label: const Text('مريح'),
                        selected:
                            themeProvider.readingMode == ReadingMode.comfort,
                        onSelected: (_) =>
                            themeProvider.setReadingMode(ReadingMode.comfort),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, Color> _getThemeColors(EnhancedThemeProvider provider) {
    switch (provider.readingMode) {
      case ReadingMode.night:
        return {
          'background': const Color(0xFF1A1A1A),
          'surface': const Color(0xFF2C2C2C),
          'text': const Color(0xFFE8E8E8),
          'primary': const Color(0xFF4CAF50),
        };
      case ReadingMode.comfort:
        return {
          'background': const Color(0xFFF5E6D3),
          'surface': const Color(0xFFFAF8F3),
          'text': const Color(0xFF3E2723),
          'primary': const Color(0xFF6D4C41),
        };
      default:
        return {
          'background': const Color(0xFFFAFAFA),
          'surface': const Color(0xFFFFFFFF),
          'text': const Color(0xFF212121),
          'primary': const Color(0xFF4CAF50),
        };
    }
  }
}
