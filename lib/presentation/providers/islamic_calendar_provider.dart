import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../domain/entities/islamic_event_entity.dart';
import '../../domain/usecases/get_hijri_date_usecase.dart';
import '../../domain/usecases/get_islamic_events_usecase.dart';

class IslamicCalendarProvider extends ChangeNotifier {
  final GetHijriDateUseCase _getHijriDateUseCase;
  final GetIslamicEventsUseCase _getIslamicEventsUseCase;

  late HijriCalendar _currentHijriDate;
  late HijriCalendar _selectedDate;
  List<IslamicEventEntity> _eventsForMonth = [];
  IslamicEventEntity? _nextEvent;

  IslamicCalendarProvider(
    this._getHijriDateUseCase,
    this._getIslamicEventsUseCase,
  ) {
    _currentHijriDate = _getHijriDateUseCase.execute();
    _selectedDate = _currentHijriDate;
    _loadEvents();
  }

  HijriCalendar get currentHijriDate => _currentHijriDate;
  HijriCalendar get selectedDate => _selectedDate;
  List<IslamicEventEntity> get eventsForMonth => _eventsForMonth;
  IslamicEventEntity? get nextEvent => _nextEvent;

  void _loadEvents() {
    _eventsForMonth = _getIslamicEventsUseCase.execute(_selectedDate.hMonth);
    _nextEvent = _getIslamicEventsUseCase.getNextEvent();
    notifyListeners();
  }

  void selectDate(HijriCalendar date) {
    _selectedDate = date;
    // If month changed, reload events
    if (_selectedDate.hMonth != _eventsForMonth.firstOrNull?.hijriMonth) {
      _loadEvents();
    } else {
      notifyListeners();
    }
  }
  
  void nextMonth() {
    // HijriCalendar doesn't have a simple 'addMonth', so we might need to handle this carefully
    // For simplicity in MVP, we can just increment month and handle year wrap
    int newMonth = _selectedDate.hMonth + 1;
    int newYear = _selectedDate.hYear;
    
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    
    _selectedDate = HijriCalendar();
    _selectedDate.hYear = newYear;
    _selectedDate.hMonth = newMonth;
    _selectedDate.hDay = 1;
    // We need to set lengthOfMonth or just rely on the object to be valid
    // HijriCalendar is a bit tricky, usually better to go via DateTime if needed, 
    // but let's try to stick to Hijri if possible or convert back/forth
    
    _loadEvents();
  }

  void previousMonth() {
    int newMonth = _selectedDate.hMonth - 1;
    int newYear = _selectedDate.hYear;
    
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    
    _selectedDate = HijriCalendar();
    _selectedDate.hYear = newYear;
    _selectedDate.hMonth = newMonth;
    _selectedDate.hDay = 1;
    
    _loadEvents();
  }
}
