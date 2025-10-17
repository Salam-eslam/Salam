class ReadingProgress {
  final int surahNumber;
  final String surahName;
  final int lastReadAyah;
  final DateTime lastReadTime;
  final int totalAyahs;

  ReadingProgress({
    required this.surahNumber,
    required this.surahName,
    required this.lastReadAyah,
    required this.lastReadTime,
    required this.totalAyahs,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      surahNumber: json['surahNumber'],
      surahName: json['surahName'],
      lastReadAyah: json['lastReadAyah'],
      lastReadTime: DateTime.parse(json['lastReadTime']),
      totalAyahs: json['totalAyahs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'lastReadAyah': lastReadAyah,
      'lastReadTime': lastReadTime.toIso8601String(),
      'totalAyahs': totalAyahs,
    };
  }

  double get progressPercentage {
    // Calculate percentage: current ayah / total ayahs
    // This matches the scroll-based calculation
    // Example: Ayah 1 of 7 = 14.3%, Ayah 7 of 7 = 100%
    if (lastReadAyah == 0 || totalAyahs == 0) return 0.0;
    return (lastReadAyah / totalAyahs) * 100;
  }
}
