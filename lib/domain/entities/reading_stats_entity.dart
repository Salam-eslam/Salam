import 'package:equatable/equatable.dart';

class ReadingStatsEntity extends Equatable {
  final DateTime date;
  final int versesRead;
  final int timeSpentSeconds;

  const ReadingStatsEntity({
    required this.date,
    required this.versesRead,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'versesRead': versesRead,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  factory ReadingStatsEntity.fromJson(Map<String, dynamic> json) {
    return ReadingStatsEntity(
      date: DateTime.parse(json['date']),
      versesRead: json['versesRead'],
      timeSpentSeconds: json['timeSpentSeconds'],
    );
  }

  @override
  List<Object?> get props => [date, versesRead, timeSpentSeconds];
}
