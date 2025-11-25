import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/islamic_calendar_provider.dart';

class IslamicCalendarScreen extends StatelessWidget {
  const IslamicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => context
          .read<IslamicCalendarProvider>(), // Assuming provided by parent or DI
      // Actually, we usually use the DI factory in the route or parent
      // But for now let's assume it's provided above or we create it here using GetIt if needed
      // In this project, providers are usually created in main.dart or route generation
      // Let's check how other screens do it. CommunityScreen uses Consumer but provider is created in main?
      // No, main.dart uses MultiProvider. We need to add this provider to main.dart or create it here.
      // Let's create it here for now using GetIt to be safe and self-contained,
      // or better, assume it's added to the global MultiProvider if that's the pattern.
      // Looking at main.dart (from memory/context), it has a list of providers.
      // I should probably add it there too, but for now let's wrap it here.
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Islamic Calendar'),
          ),
          body: Consumer<IslamicCalendarProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Month Navigation
                  _buildMonthHeader(context, provider),

                  // Calendar Grid
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCalendarGrid(context, provider),
                          const Divider(),
                          _buildEventsList(context, provider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader(
      BuildContext context, IslamicCalendarProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: provider.previousMonth,
          ),
          Text(
            '${provider.selectedDate.toFormat("MMMM yyyy")}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: provider.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      BuildContext context, IslamicCalendarProvider provider) {
    // Simple grid for MVP.
    // Note: HijriCalendar doesn't give easy "days in month" or "weekday of 1st" directly
    // without some calculation or using the library's internal logic.
    // The `hijri` package has `getDaysInMonth(year, month)`.

    final daysInMonth = provider.selectedDate.getDaysInMonth(
        provider.selectedDate.hYear, provider.selectedDate.hMonth);

    // We need to know which weekday the 1st of the month falls on.
    // We can convert Hijri(year, month, 1) to Gregorian and get weekday.
    final firstDayHijri = HijriCalendar();
    firstDayHijri.hYear = provider.selectedDate.hYear;
    firstDayHijri.hMonth = provider.selectedDate.hMonth;
    firstDayHijri.hDay = 1;
    final firstDayGregorian = firstDayHijri.hijriToGregorian(
        firstDayHijri.hYear, firstDayHijri.hMonth, 1);
    final startWeekday = firstDayGregorian.weekday; // 1 = Mon, 7 = Sun

    // Adjust for Sunday start if needed, but standard is usually Mon or Sun.
    // Let's assume standard grid.

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + (startWeekday % 7), // Offset
      itemBuilder: (context, index) {
        if (index < (startWeekday % 7)) {
          return const SizedBox();
        }

        final day = index - (startWeekday % 7) + 1;
        final isToday = provider.currentHijriDate.hYear ==
                provider.selectedDate.hYear &&
            provider.currentHijriDate.hMonth == provider.selectedDate.hMonth &&
            provider.currentHijriDate.hDay == day;

        final hasEvent = provider.eventsForMonth.any((e) => e.hijriDay == day);

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isToday
                ? Theme.of(context).primaryColor
                : (hasEvent
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null),
            shape: BoxShape.circle,
            border: isToday ? null : Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              color: isToday
                  ? Colors.white
                  : (hasEvent ? Theme.of(context).primaryColor : null),
              fontWeight:
                  isToday || hasEvent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsList(
      BuildContext context, IslamicCalendarProvider provider) {
    if (provider.eventsForMonth.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No major events this month.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.eventsForMonth.length,
      itemBuilder: (context, index) {
        final event = provider.eventsForMonth[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.2),
            child: Text('${event.hijriDay}'),
          ),
          title: Text(event.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(event.description),
          trailing: event.isMajor
              ? const Icon(Icons.star, color: Colors.amber)
              : null,
        );
      },
    );
  }
}
