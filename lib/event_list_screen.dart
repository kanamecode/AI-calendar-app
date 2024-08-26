import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';

class EventListScreen extends StatelessWidget {
  final Map<DateTime, List<Event>> events;

  // ignore: use_key_in_widget_constructors
  const EventListScreen({required this.events});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = events.entries
        .where((entry) =>
            entry.value.isNotEmpty) // Exclude entries with empty event lists
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      children: sortedEntries.map((entry) {
        DateTime date = entry.key;
        List<Event> eventList = entry.value;

        eventList.sort((a, b) {
          if (a.isAllDay && !b.isAllDay) {
            return -1;
          }
          if (!a.isAllDay && b.isAllDay) {
            return 1;
          }

          final startTimeA = a.startTime ?? const TimeOfDay(hour: 0, minute: 0);
          final startTimeB = b.startTime ?? const TimeOfDay(hour: 0, minute: 0);
          int startTimeComparison =
              startTimeA.hour.compareTo(startTimeB.hour) == 0
                  ? startTimeA.minute.compareTo(startTimeB.minute)
                  : startTimeA.hour.compareTo(startTimeB.hour);

          if (startTimeComparison != 0) {
            return startTimeComparison;
          }

          final endTimeA = a.endTime ?? const TimeOfDay(hour: 23, minute: 59);
          final endTimeB = b.endTime ?? const TimeOfDay(hour: 23, minute: 59);
          return endTimeA.hour.compareTo(endTimeB.hour) == 0
              ? endTimeA.minute.compareTo(endTimeB.minute)
              : endTimeA.hour.compareTo(endTimeB.hour);
        });

        String formattedDate = DateFormat('yyyy-MM-dd', 'ja_JP').format(date);
        String weekday = _getWeekdayOneLetter(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                '$formattedDate ($weekday)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color.fromARGB(255, 0, 81, 255),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...eventList.map((event) {
              String timeRange = event.isAllDay
                  ? '終日'
                  : '${event.startTime?.format(context) ?? ''} - ${event.endTime?.format(context) ?? ''}';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ignore: sized_box_for_whitespace
                    Container(
                      width: 100.0,
                      child: Text(
                        timeRange,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(137, 206, 206, 206),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    Expanded(
                      // ignore: avoid_unnecessary_containers
                      child: Container(
                        child: Text(
                          event.title,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(event.title),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('日付: ${DateFormat('yyyy-MM-dd').format(date)}'),
                          if (event.description.isNotEmpty)
                            Text('説明: ${event.description}'),
                          if (event.location != null &&
                              event.location!.isNotEmpty)
                            Text('場所: ${event.location}'),
                          if (event.startTime != null && event.endTime != null)
                            Text(
                                '時間: ${event.startTime?.format(context)} - ${event.endTime?.format(context)}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: const Text('閉じる'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              );
              // ignore: unnecessary_to_list_in_spreads
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  String _getWeekdayOneLetter(DateTime date) {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return weekdays[date.weekday - 1];
  }
}
