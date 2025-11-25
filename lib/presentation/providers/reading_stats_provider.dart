import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/reading_stats_entity.dart';

class ReadingStatsProvider with ChangeNotifier {
  List<ReadingStatsEntity> _stats = [];

  List<ReadingStatsEntity> get stats => _stats;

  ReadingStatsProvider() {
    _loadStats();
  }

  Future<void> addSession(int versesRead, int timeSpentSeconds) async {
    if (versesRead == 0 && timeSpentSeconds == 0) return;

    final now = DateTime.now();
    // Check if we already have an entry for today
    final todayIndex = _stats.indexWhere((stat) =>
        stat.date.year == now.year &&
        stat.date.month == now.month &&
        stat.date.day == now.day);

    if (todayIndex != -1) {
      // Update today's stats
      final current = _stats[todayIndex];
      _stats[todayIndex] = ReadingStatsEntity(
        date: current.date,
        versesRead: current.versesRead + versesRead,
        timeSpentSeconds: current.timeSpentSeconds + timeSpentSeconds,
      );
    } else {
      // Add new entry
      _stats.add(ReadingStatsEntity(
        date: now,
        versesRead: versesRead,
        timeSpentSeconds: timeSpentSeconds,
      ));
    }

    await _saveStats();
    notifyListeners();
  }

  int getTotalVersesRead() {
    return _stats.fold(0, (sum, item) => sum + item.versesRead);
  }

  int getTotalTimeSpent() {
    return _stats.fold(0, (sum, item) => sum + item.timeSpentSeconds);
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getStringList('reading_stats');

    if (statsJson != null) {
      _stats = statsJson
          .map((str) => ReadingStatsEntity.fromJson(json.decode(str)))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = _stats.map((stat) => json.encode(stat.toJson())).toList();
    await prefs.setStringList('reading_stats', statsJson);
  }
}
