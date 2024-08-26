import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class SchedulePlannerScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String eventName;
  final String period;
  final String eventDetails;
  final String location;
  final String timeRange;
  final String comment;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int selectedHours;
  final int selectedMinutes;
  final VoidCallback? onHomeButtonPressed;

  // ignore: use_super_parameters
  const SchedulePlannerScreen({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.eventName,
    required this.period,
    required this.eventDetails,
    required this.location,
    required this.timeRange,
    required this.comment,
    required this.selectedHours,
    required this.selectedMinutes,
    this.startTime,
    this.endTime,
    this.onHomeButtonPressed,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SchedulePlannerScreenState createState() => _SchedulePlannerScreenState();
}

class _SchedulePlannerScreenState extends State<SchedulePlannerScreen> {
  final Map<DateTime, List<Event>> _events = {};
  List<Event> _eventsInRange = [];
  // ignore: unused_field
  final List<Event> _parsedEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _autoSendEventsToChatGPT();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString('events');

    if (eventsJson != null) {
      final Map<String, dynamic> decodedEvents = jsonDecode(eventsJson);
      setState(() {
        _events.clear();
        decodedEvents.forEach((key, value) {
          final date = DateTime.parse(key);
          final eventsList = List<Map<String, dynamic>>.from(value);
          _events[date] = eventsList.map((eventMap) {
            return Event(
              title: eventMap['title'],
              description: eventMap['description'],
              isAllDay: eventMap['isAllDay'],
              startTime: eventMap['startTime'] != null
                  ? TimeOfDay(
                      hour: eventMap['startTime']['hour'],
                      minute: eventMap['startTime']['minute'])
                  : null,
              endTime: eventMap['endTime'] != null
                  ? TimeOfDay(
                      hour: eventMap['endTime']['hour'],
                      minute: eventMap['endTime']['minute'])
                  : null,
              location: eventMap['location'],
              date: date,
              isNew: false,
              isSaved: eventMap['isSaved'] ?? false,
            );
          }).toList();
        });

        _filterEventsInRange();
      });
    }
  }

  void _filterEventsInRange() {
    _eventsInRange = [];
    _events.forEach((date, events) {
      if (date.isAfter(widget.startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(widget.endDate.add(const Duration(days: 1))) &&
          (date.isAtSameMomentAs(widget.startDate) ||
              date.isAfter(widget.startDate) &&
                  date.isBefore(widget.endDate.add(const Duration(days: 1))))) {
        _eventsInRange.addAll(events);
      }
    });

    _eventsInRange.sort((a, b) {
      if (a.date != b.date) {
        return a.date.compareTo(b.date);
      }
      if (a.isAllDay && !b.isAllDay) {
        return -1;
      }
      if (!a.isAllDay && b.isAllDay) {
        return 1;
      }
      if (a.startTime != null && b.startTime != null) {
        final aStartMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
        final bStartMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
        return aStartMinutes.compareTo(bStartMinutes);
      }
      return 0;
    });

    setState(() {});
  }

  Future<void> _autoSendEventsToChatGPT() async {
    await _sendEventsToChatGPT();
  }

  Future<void> _sendEventsToChatGPT() async {
    final prefs = await SharedPreferences.getInstance();
  // ignore: unused_local_variable
  final apiKey = prefs.getString('chatGptApiKey');
  if (apiKey == null || apiKey.isEmpty) {
  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('APIキーが設定されていません。設定画面で入力してください。')),
  );
  return;
}

  
    final eventsJson = _eventsToJson();
    final additionalData = {
      'eventName': widget.eventName,
      'period': widget.period,
      'eventDetails': widget.eventDetails,
      'location': widget.location,
      'timeRange': widget.timeRange,
      'comment': widget.comment,
      'selectedHours': widget.selectedHours,
      'selectedMinutes': widget.selectedMinutes,
    };

    List<Map<String, String>> chatMessages = [
      {
        'role': 'user',
        'content':
            'I will output in the following JSON format, ensuring that it does not overlap with the start and end times of all-day events or other events. No explanation is needed. The following is an example of the output format. If details or location are not specified, they will be left blank. Only output the JSON.:\n\n'
                '{\n'
                'Example output:\n'
                '{\n'
                '  "title": "Project Meeting",\n'
                '  "description": "Discuss project status and next steps",\n'
                '  "isAllDay": false,\n'
                '  "startTime": {"hour": 14, "minute": 0},\n'
                '  "endTime": {"hour": 15, "minute": 0},\n'
                '  "location": "Conference Room A",\n'
                '  "date": "2024-08-12T00:00:00Z"\n'
                '}\n\n'
                'Read the title and period from the content of the comment if they are not entered.The provided list includes start and end times. Ensure that the specified time does not overlap with these times.The specified time represents the duration of the event, not a specific time, and it is not the start or end time.Here is the current list of events.Also include the title of the event on the last day of the list as it is.: $eventsJson with additional information: ${jsonEncode(additionalData)}.'
      }
    ];

    try {
      const apiUrl = 'https://api.openai.com/v1/chat/completions';
      //final apiKey = dotenv.env['CHATGPT_API_KEY'] ?? ''; // ChatGPT API key

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': chatMessages,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(responseBody);
        String assistantMessage =
            data['choices'][0]['message']['content'].toString();
        _parseChatGPTResponse(assistantMessage);
      } else {
        debugPrint('Error: ${response.statusCode} - ${response.reasonPhrase}');
        debugPrint('Response Body: ${response.body}');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('通信に失敗しました。\nエラーコード: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リクエスト中にエラーが発生しました。\nもう一度試してみてください。'),
        ),
      );
    }
  }

  void _parseChatGPTResponse(String response) {
    try {
      final parsed = jsonDecode(response) as Map<String, dynamic>;
      final event = Event(
        title: parsed['title'],
        description: parsed['description'] ?? '',
        isAllDay: parsed['isAllDay'],
        startTime: parsed['startTime'] != null
            ? TimeOfDay(
                hour: parsed['startTime']['hour'],
                minute: parsed['startTime']['minute'])
            : null,
        endTime: parsed['endTime'] != null
            ? TimeOfDay(
                hour: parsed['endTime']['hour'],
                minute: parsed['endTime']['minute'])
            : null,
        location: parsed['location'],
        date: DateTime.parse(parsed['date']),
        isNew: true,
        isSaved: false,
      );

      setState(() {
        _eventsInRange.add(event);
        _eventsInRange.sort((a, b) {
          if (a.date != b.date) {
            return a.date.compareTo(b.date);
          }
          if (a.isAllDay && !b.isAllDay) {
            return -1;
          }
          if (!a.isAllDay && b.isAllDay) {
            return 1;
          }
          if (a.startTime != null && b.startTime != null) {
            final aStartMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
            final bStartMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
            return aStartMinutes.compareTo(bStartMinutes);
          }
          return 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('イベント「${event.title}」が作成されました。'),
          ),
        );
      });
    } catch (e) {
      debugPrint('Failed to parse ChatGPT response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          '予定の作成に失敗しました。\n'
          'もう一度実行するか、指定した内容をお確かめください。',
        )),
      );
    }
  }

  String _eventsToJson() {
    final List<Map<String, dynamic>> eventsList = _eventsInRange.map((event) {
      return {
        'title': event.title,
        'description': event.description,
        'isAllDay': event.isAllDay,
        'startTime': event.startTime != null
            ? {'hour': event.startTime!.hour, 'minute': event.startTime!.minute}
            : null,
        'endTime': event.endTime != null
            ? {'hour': event.endTime!.hour, 'minute': event.endTime!.minute}
            : null,
        'location': event.location,
        'date': event.date.toIso8601String(),
        'isSaved': event.isSaved,
      };
    }).toList();

    return jsonEncode(eventsList);
  }

  Future<void> _saveEvent(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '{}';
    final Map<String, dynamic> decodedEvents = jsonDecode(eventsJson);

    final dateString = event.date.toIso8601String();
    if (!decodedEvents.containsKey(dateString)) {
      decodedEvents[dateString] = [];
    }

    final eventJson = {
      'title': event.title,
      'description': event.description,
      'isAllDay': event.isAllDay,
      'startTime': event.startTime != null
          ? {'hour': event.startTime!.hour, 'minute': event.startTime!.minute}
          : null,
      'endTime': event.endTime != null
          ? {'hour': event.endTime!.hour, 'minute': event.endTime!.minute}
          : null,
      'location': event.location,
      'date': event.date.toIso8601String(),
      'isSaved': true,
    };

    final eventsList =
        List<Map<String, dynamic>>.from(decodedEvents[dateString]);
    eventsList.add(eventJson);
    decodedEvents[dateString] = eventsList;

    await prefs.setString('events', jsonEncode(decodedEvents));
  }

  Future<void> _deleteEvent(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '{}';
    final Map<String, dynamic> decodedEvents = jsonDecode(eventsJson);

    final dateString = event.date.toIso8601String();
    if (decodedEvents.containsKey(dateString)) {
      final eventsList =
          List<Map<String, dynamic>>.from(decodedEvents[dateString]);
      eventsList.removeWhere((e) =>
          e['title'] == event.title &&
          e['date'] == event.date.toIso8601String());
      decodedEvents[dateString] = eventsList;

      if (eventsList.isEmpty) {
        decodedEvents.remove(dateString);
      }

      await prefs.setString('events', jsonEncode(decodedEvents));
    }
  }

  void _handleEventTap(Event event) async {
    if (event.isSaved) {
      // If event is already saved, delete it
      await _deleteEvent(event);
      setState(() {
        event.isSaved = false;
        event.isNew = true;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベント"${event.title}" をキャンセルしました')),
      );
    } else {
      // If event is not saved, save it
      await _saveEvent(event);
      setState(() {
        event.isSaved = true;
        event.isNew = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('イベント"${event.title}" を保存しました')),
      );
    }
  }

  void _deleteUnsavedEvents() {
    setState(() {
      _eventsInRange.removeWhere((event) => !event.isSaved);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('自動作成された保存されていないイベントを削除しました。'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI自動作成'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _deleteUnsavedEvents(); // Function to delete unsaved events
              _loadEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              onReloadEvents!(); // call back
              Navigator.of(context).popUntil(ModalRoute.withName(
                  '/')); // Adjust '/ ' to your main route name if necessary
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _eventsInRange.length,
        itemBuilder: (context, index) {
          final event = _eventsInRange[index];
          return Card(
            color: event.isSaved
                ? const Color.fromARGB(
                    255, 53, 139, 0) // Green for saved events
                : event.isNew
                    ? const Color.fromARGB(
                        255, 174, 134, 0) // Orange for new events
                    : const Color.fromARGB(
                        255, 81, 81, 81), // Gray for unsaved events
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(event.title),
              subtitle: Text(
                '${event.description}\n'
                '${event.isAllDay ? '終日' : '開始: ${event.startTime?.format(context)} 〜 終了: ${event.endTime?.format(context) ?? '不明'}\n'}'
                '場所: ${event.location ?? '場所指定なし'}\n'
                '日付: ${DateFormat('yyyy-MM-dd').format(event.date)}',
              ),
              onTap: () => _handleEventTap(event),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendEventsToChatGPT,
        child: const Icon(Icons.repeat),
      ),
    );
  }
}

class Event {
  String title;
  String description;
  bool isAllDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? location;
  DateTime date;
  bool isNew;
  bool isSaved;

  Event({
    required this.title,
    required this.description,
    required this.isAllDay,
    this.startTime,
    this.endTime,
    this.location,
    required this.date,
    this.isNew = false,
    this.isSaved = false,
  });
}
