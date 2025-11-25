import '../../domain/entities/islamic_event_entity.dart';
import '../../services/hijri_calendar_service.dart';

class GetIslamicEventsUseCase {
  final HijriCalendarService _service;

  GetIslamicEventsUseCase(this._service);

  List<IslamicEventEntity> execute(int hijriMonth) {
    return _service.getEventsForMonth(hijriMonth);
  }
  
  IslamicEventEntity? getNextEvent() {
    return _service.getNextEvent();
  }
}
