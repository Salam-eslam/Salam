import 'package:flutter/material.dart';
import '../../domain/entities/quran_page_entity.dart';

// Helper functions for consistent font styling using system fonts
TextStyle _safeAmiriFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFamily: 'serif', // System serif font for Arabic text
  );
}

TextStyle _safeLatoFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFamily: 'sans-serif', // System sans-serif font
  );
}

class QuranPageWidget extends StatelessWidget {
  final QuranPage page;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final bool showJuzIndicator;

  const QuranPageWidget({
    Key? key,
    required this.page,
    this.backgroundColor = const Color(0xFFFAF8F3),
    this.textColor = const Color(0xFF2C1810),
    this.fontSize = 20.0,
    this.showJuzIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Decorative corner ornaments
            _buildCornerOrnaments(),

            // Main content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildPageContent(),
                ),
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerOrnaments() {
    return Stack(
      children: [
        // Top-left ornament
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _CornerOrnamentPainter(
              color: textColor.withValues(alpha: 0.15),
              isTopLeft: true,
            ),
          ),
        ),
        // Top-right ornament
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _CornerOrnamentPainter(
              color: textColor.withValues(alpha: 0.15),
              isTopRight: true,
            ),
          ),
        ),
        // Bottom-left ornament
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _CornerOrnamentPainter(
              color: textColor.withValues(alpha: 0.15),
              isBottomLeft: true,
            ),
          ),
        ),
        // Bottom-right ornament
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _CornerOrnamentPainter(
              color: textColor.withValues(alpha: 0.15),
              isBottomRight: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            textColor.withValues(alpha: 0.05),
            backgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: textColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showJuzIndicator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    textColor.withValues(alpha: 0.12),
                    textColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: textColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الجزء ${_arabicNumber(page.juzNumber)}',
                    style: _safeAmiriFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              page.ayahs.isNotEmpty ? page.ayahs.first.surahNameArabic : '',
              style: _safeAmiriFont(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Check if this is the start of a new surah
          if (_isNewSurahStart()) _buildSurahHeader(),

          // Build the ayahs in a flowing text format
          _buildAyahsText(),
        ],
      ),
    );
  }

  bool _isNewSurahStart() {
    if (page.ayahs.isEmpty) return false;

    // Check if first ayah is the first ayah of a surah (excluding Al-Fatihah and At-Tawbah)
    final firstAyah = page.ayahs.first;
    if (firstAyah.numberInSurah == 1 &&
        firstAyah.surahNumber != 1 &&
        firstAyah.surahNumber != 9) {
      return true;
    }

    return false;
  }

  Widget _buildSurahHeader() {
    final firstAyah = page.ayahs.first;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Decorative top ornament
          _buildDecorativeOrnament(),

          const SizedBox(height: 16),

          // Surah name container with border
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  textColor.withValues(alpha: 0.08),
                  textColor.withValues(alpha: 0.04),
                  textColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: textColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Surah name in Arabic
                Text(
                  'سُورَةُ ${firstAyah.surahNameArabic}',
                  style: _safeAmiriFont(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.8,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Surah name in English
                Text(
                  firstAyah.surahName,
                  style: _safeLatoFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Basmallah (except for At-Tawbah) - shown as decoration, not as a verse
          if (firstAyah.surahNumber != 9 && firstAyah.surahNumber != 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                style: _safeAmiriFont(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.9),
                  height: 2,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Decorative bottom ornament
          _buildDecorativeOrnament(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDecorativeOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOrnamentLine(50),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                textColor.withValues(alpha: 0.4),
                textColor.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: textColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                textColor.withValues(alpha: 0.4),
                textColor.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildOrnamentLine(50),
      ],
    );
  }

  Widget _buildOrnamentLine(double width) {
    return Container(
      width: width,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            textColor.withValues(alpha: 0),
            textColor.withValues(alpha: 0.3),
            textColor.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahsText() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: _safeAmiriFont(
            fontSize: fontSize,
            height: 2.2,
            color: textColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          children: page.ayahs.map((ayah) {
            return TextSpan(
              children: [
                TextSpan(
                  text: ayah.text,
                  style: TextStyle(
                    shadows: [
                      Shadow(
                        color: textColor.withValues(alpha: 0.1),
                        offset: const Offset(0, 0.5),
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                ),
                const TextSpan(text: ' '),
                // Ayah number in a decorative circle
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    width: fontSize * 1.4,
                    height: fontSize * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          textColor.withValues(alpha: 0.08),
                          textColor.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.35),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withValues(alpha: 0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _arabicNumber(ayah.numberInSurah),
                        style: _safeAmiriFont(
                          fontSize: fontSize * 0.55,
                          color: textColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' '),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            textColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: textColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  textColor.withValues(alpha: 0.12),
                  textColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: textColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _arabicNumber(page.pageNumber),
                  style: _safeAmiriFont(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Convert number to Arabic-Indic numerals
  String _arabicNumber(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      if (digit.contains(RegExp(r'[0-9]'))) {
        return arabicNumerals[int.parse(digit)];
      }
      return digit;
    }).join();
  }
}

// Custom painter for corner ornaments
class _CornerOrnamentPainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerOrnamentPainter({
    required this.color,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTopLeft) {
      // Top-left corner ornament
      path.moveTo(0, size.height * 0.5);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.5, 0);

      // Add decorative arc
      path.moveTo(size.width * 0.3, 0);
      path.quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.3,
        0,
        size.height * 0.3,
      );
    } else if (isTopRight) {
      // Top-right corner ornament
      path.moveTo(size.width, size.height * 0.5);
      path.lineTo(size.width, 0);
      path.lineTo(size.width * 0.5, 0);

      // Add decorative arc
      path.moveTo(size.width * 0.7, 0);
      path.quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.3,
        size.width,
        size.height * 0.3,
      );
    } else if (isBottomLeft) {
      // Bottom-left corner ornament
      path.moveTo(0, size.height * 0.5);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.5, size.height);

      // Add decorative arc
      path.moveTo(size.width * 0.3, size.height);
      path.quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.7,
        0,
        size.height * 0.7,
      );
    } else if (isBottomRight) {
      // Bottom-right corner ornament
      path.moveTo(size.width, size.height * 0.5);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * 0.5, size.height);

      // Add decorative arc
      path.moveTo(size.width * 0.7, size.height);
      path.quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.7,
        size.width,
        size.height * 0.7,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
