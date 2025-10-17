class QuranPage {
  final int pageNumber;
  final int juzNumber;
  final List<PageAyah> ayahs;
  final String? juzName;

  QuranPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.ayahs,
    this.juzName,
  });

  factory QuranPage.fromJson(Map<String, dynamic> json) {
    return QuranPage(
      pageNumber: json['page'] as int,
      juzNumber: json['juz'] as int,
      ayahs: (json['ayahs'] as List)
          .map((ayah) => PageAyah.fromJson(ayah))
          .toList(),
      juzName: json['juzName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': pageNumber,
      'juz': juzNumber,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
      'juzName': juzName,
    };
  }
}

class PageAyah {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int ayahNumber;
  final String text;
  final int numberInSurah;

  PageAyah({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.text,
    required this.numberInSurah,
  });

  factory PageAyah.fromJson(Map<String, dynamic> json) {
    return PageAyah(
      surahNumber: json['surahNumber'] as int,
      surahName: json['surahName'] as String,
      surahNameArabic: json['surahNameArabic'] as String,
      ayahNumber: json['ayahNumber'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'surahNameArabic': surahNameArabic,
      'ayahNumber': ayahNumber,
      'text': text,
      'numberInSurah': numberInSurah,
    };
  }
}
