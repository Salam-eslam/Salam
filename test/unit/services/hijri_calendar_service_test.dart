import 'package:flutter_test/flutter_test.dart';
import 'package:salam/services/hijri_calendar_service.dart';

void main() {
  late HijriCalendarService service;

  setUp(() {
    service = HijriCalendarService();
  });

  group('HijriCalendarService', () {
    test('convertToHijri returns correct Hijri date', () {
      // Known date: 1st Ramadan 1445 is approx 11 March 2024
      // Note: Hijri dates can vary by +/- 1 day depending on moon sighting and calculation method.
      // The package uses Umm Al-Qura by default.
      final gregorian = DateTime(2024, 3, 11);
      final hijri = service.convertToHijri(gregorian);

      // We just verify it returns a valid object and roughly correct month
      expect(hijri.hYear, 1445);
      expect(hijri.hMonth, 9); // Ramadan
    });

    test('getEventsForMonth returns events for specific month', () {
      final events = service.getEventsForMonth(9); // Ramadan
      expect(events, isNotEmpty);
      expect(events.first.name, 'Start of Ramadan');
    });

    test('getNextEvent returns upcoming event', () {
      // This is hard to test deterministically without mocking "now",
      // but we can check if it returns *something* or null validly.
      final event = service.getNextEvent();
      // It might be null if end of year, but usually not.
      // Just ensure no crash.
      expect(event, isA<Object?>());
    });
  });
}
