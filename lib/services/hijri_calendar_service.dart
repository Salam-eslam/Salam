import 'package:hijri/hijri_calendar.dart';
import '../domain/entities/islamic_event_entity.dart';
import '../data/datasources/islamic_events_data.dart';

class HijriCalendarService {
  /// Converts a Gregorian date to Hijri
  HijriCalendar convertToHijri(DateTime date) {
    return HijriCalendar.fromDate(date);
  }

  /// Returns the current Hijri date
  HijriCalendar now() {
    return HijriCalendar.now();
  }

  /// Returns a list of Islamic events for a given Hijri month
  List<IslamicEventEntity> getEventsForMonth(int hijriMonth) {
    return IslamicEventsData.allEvents
        .where((event) => event.hijriMonth == hijriMonth)
        .toList();
  }

  /// Returns the next upcoming event relative to the current Hijri date
  IslamicEventEntity? getNextEvent() {
    final currentHijri = now();
    final currentMonth = currentHijri.hMonth;
    final currentDay = currentHijri.hDay;

    // Sort events by month and day
    final sortedEvents = List<IslamicEventEntity>.from(IslamicEventsData.allEvents)
      ..sort((a, b) {
        if (a.hijriMonth != b.hijriMonth) {
          return a.hijriMonth.compareTo(b.hijriMonth);
        }
        return a.hijriDay.compareTo(b.hijriDay);
      });

    // Find the first event that is after today
    for (final event in sortedEvents) {
      if (event.hijriMonth > currentMonth ||
          (event.hijriMonth == currentMonth && event.hijriDay >= currentDay)) {
        return event;
      }
    }

    // If no event left this year, return the first event of next year
    if (sortedEvents.isNotEmpty) {
      return sortedEvents.first;
    }

    return null;
  }
}
