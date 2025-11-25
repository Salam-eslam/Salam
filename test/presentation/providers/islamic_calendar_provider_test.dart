import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:salam/domain/usecases/get_hijri_date_usecase.dart';
import 'package:salam/domain/usecases/get_islamic_events_usecase.dart';
import 'package:salam/presentation/providers/islamic_calendar_provider.dart';

// Generate mocks
@GenerateMocks([GetHijriDateUseCase, GetIslamicEventsUseCase])
import 'islamic_calendar_provider_test.mocks.dart';

void main() {
  late IslamicCalendarProvider provider;
  late MockGetHijriDateUseCase mockGetHijriDateUseCase;
  late MockGetIslamicEventsUseCase mockGetIslamicEventsUseCase;

  setUp(() {
    mockGetHijriDateUseCase = MockGetHijriDateUseCase();
    mockGetIslamicEventsUseCase = MockGetIslamicEventsUseCase();

    // Setup default behavior
    final today = HijriCalendar();
    today.hYear = 1445;
    today.hMonth = 9;
    today.hDay = 1;

    when(mockGetHijriDateUseCase.execute()).thenReturn(today);
    when(mockGetIslamicEventsUseCase.execute(any)).thenReturn([]);
    when(mockGetIslamicEventsUseCase.getNextEvent()).thenReturn(null);

    provider = IslamicCalendarProvider(
      mockGetHijriDateUseCase,
      mockGetIslamicEventsUseCase,
    );
  });

  test('initial state is correct', () {
    expect(provider.currentHijriDate.hMonth, 9);
    expect(provider.selectedDate.hMonth, 9);
    verify(mockGetIslamicEventsUseCase.execute(9)).called(1);
  });

  test('selectDate updates selectedDate and reloads events if month changes',
      () {
    final newDate = HijriCalendar();
    newDate.hYear = 1445;
    newDate.hMonth = 10;
    newDate.hDay = 1;

    provider.selectDate(newDate);

    expect(provider.selectedDate.hMonth, 10);
    verify(mockGetIslamicEventsUseCase.execute(10)).called(1);
  });

  test('nextMonth increments month correctly', () {
    // Initial month is 9
    provider.nextMonth();

    expect(provider.selectedDate.hMonth, 10);
    verify(mockGetIslamicEventsUseCase.execute(10)).called(1);
  });

  test('previousMonth decrements month correctly', () {
    // Initial month is 9
    provider.previousMonth();

    expect(provider.selectedDate.hMonth, 8);
    verify(mockGetIslamicEventsUseCase.execute(8)).called(1);
  });
}
