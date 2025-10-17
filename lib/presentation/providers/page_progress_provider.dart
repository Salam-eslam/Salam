import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../data/models/page_progress.dart';

class PageProgressProvider with ChangeNotifier {
  static const String _boxName = 'page_progress';
  Box<PageProgress>? _box;
  PageProgress? _currentProgress;

  PageProgress? get currentProgress => _currentProgress;

  double get progressPercentage =>
      _currentProgress?.progressPercentage ?? 0.0;

  int get lastReadPage => _currentProgress?.lastReadPage ?? 1;

  int get totalPagesRead => _currentProgress?.totalPagesRead ?? 0;

  Future<void> initialize() async {
    _box = await Hive.openBox<PageProgress>(_boxName);
    _currentProgress = _box?.get('mushaf_progress');

    if (_currentProgress == null) {
      _currentProgress = PageProgress(
        lastReadPage: 1,
        lastReadTime: DateTime.now(),
        totalPagesRead: 0,
      );
      await _saveProgress();
    }

    notifyListeners();
  }

  Future<void> updateProgress(int pageNumber) async {
    if (_currentProgress == null) {
      await initialize();
    }

    _currentProgress?.updateProgress(pageNumber);
    await _saveProgress();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    if (_box != null && _currentProgress != null) {
      await _box!.put('mushaf_progress', _currentProgress!);
    }
  }

  bool hasReadPage(int pageNumber) {
    return _currentProgress?.pageHistory.containsKey(pageNumber) ?? false;
  }

  DateTime? getPageReadTime(int pageNumber) {
    return _currentProgress?.pageHistory[pageNumber];
  }

  Future<void> resetProgress() async {
    _currentProgress = PageProgress(
      lastReadPage: 1,
      lastReadTime: DateTime.now(),
      totalPagesRead: 0,
    );
    await _saveProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }
}
