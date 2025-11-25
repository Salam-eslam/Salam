import 'package:hijri/hijri_calendar.dart';
import '../../services/hijri_calendar_service.dart';

class GetHijriDateUseCase {
  final HijriCalendarService _service;

  GetHijriDateUseCase(this._service);

  HijriCalendar execute() {
    return _service.now();
  }
}
