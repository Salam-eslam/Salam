import 'package:hive/hive.dart';

part 'page_progress.g.dart';

@HiveType(typeId: 4)
class PageProgress extends HiveObject {
  @HiveField(0)
  int lastReadPage;

  @HiveField(1)
  DateTime lastReadTime;

  @HiveField(2)
  int totalPagesRead;

  @HiveField(3)
  Map<int, DateTime> pageHistory; // Map of page number to when it was read

  PageProgress({
    required this.lastReadPage,
    required this.lastReadTime,
    this.totalPagesRead = 0,
    Map<int, DateTime>? pageHistory,
  }) : pageHistory = pageHistory ?? {};

  double get progressPercentage => (totalPagesRead / 604) * 100;

  void updateProgress(int pageNumber) {
    lastReadPage = pageNumber;
    lastReadTime = DateTime.now();

    if (!pageHistory.containsKey(pageNumber)) {
      totalPagesRead++;
      pageHistory[pageNumber] = DateTime.now();
    } else {
      pageHistory[pageNumber] = DateTime.now();
    }

    save();
  }

  Map<String, dynamic> toJson() {
    return {
      'lastReadPage': lastReadPage,
      'lastReadTime': lastReadTime.toIso8601String(),
      'totalPagesRead': totalPagesRead,
      'pageHistory': pageHistory.map(
        (key, value) => MapEntry(key.toString(), value.toIso8601String()),
      ),
    };
  }

  factory PageProgress.fromJson(Map<String, dynamic> json) {
    return PageProgress(
      lastReadPage: json['lastReadPage'] as int,
      lastReadTime: DateTime.parse(json['lastReadTime'] as String),
      totalPagesRead: json['totalPagesRead'] as int? ?? 0,
      pageHistory: (json['pageHistory'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(int.parse(key), DateTime.parse(value as String)),
          ) ??
          {},
    );
  }
}
