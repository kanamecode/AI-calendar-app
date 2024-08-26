import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: duplicate_import
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'location_picker_screen.dart';
import 'settings_screen.dart';
import 'event_list_screen.dart';
import 'package:ccalendar/auto_schedule_options.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ja_JP', null);
  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カレンダーアプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black54,
        ),
      ),
      //themeMode: ThemeMode.system,
      themeMode: ThemeMode.dark, //Set to dark mode permanently
      home: const CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => CalendarHomePageState();
}

void Function()? onReloadEvents;

class CalendarHomePageState extends State<CalendarHomePage> {
  // ignore: unused_field, prefer_final_fields
  bool _showEventList = false; // event list flag
  // ignore: prefer_final_fields
  bool _showNewButton = false;
  @override
  void initState() {
    super.initState();
    onReloadEvents = reloadEvents;
    _loadEvents(); // Load events during initialization
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents(); // Reload events when the screen is redisplayed
  }

  void reloadEvents() {
    _loadEvents();
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
            );
          }).toList();
        });
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsMap = _events.map((date, eventsList) {
      final eventsListMap = eventsList.map((event) {
        return {
          'title': event.title,
          'description': event.description,
          'isAllDay': event.isAllDay,
          'startTime': event.startTime != null
              ? {
                  'hour': event.startTime!.hour,
                  'minute': event.startTime!.minute
                }
              : null,
          'endTime': event.endTime != null
              ? {'hour': event.endTime!.hour, 'minute': event.endTime!.minute}
              : null,
          'location': event.location,
        };
      }).toList();
      return MapEntry(date.toIso8601String(), eventsListMap);
    });

    final prefsJson = jsonEncode(eventsMap);
    prefs.setString('events', prefsJson);
  }

  @override
  void dispose() {
    _saveEvents(); // Save events before the app closes
    super.dispose();
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _lastTappedDay;
  final Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  double _initialChildSize = 0.45;
  final double _maxChildSize = 0.8;
  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

// ignore: unused_element
  int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    final aDateTime = DateTime(2000, 1, 1, a.hour, a.minute);
    final bDateTime = DateTime(2000, 1, 1, b.hour, b.minute);
    return aDateTime.compareTo(bDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIカレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tips_and_updates),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AutoScheduleSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 37, 67),
              ),
              child: Text(
                'メニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('カレンダー'),
              onTap: () {
                setState(() {
                  _showEventList = false; // Select calendar display
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('スケジュール'),
              onTap: () {
                setState(() {
                  _showEventList = true; // Select event list display
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('設定'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _showEventList
          ? EventListScreen(
              events: _events, // Pass event data
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2050, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (_lastTappedDay != null &&
                              isSameDay(_lastTappedDay, selectedDay)) {
                            _addEvent();
                          } else {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _selectedEvents = _events[_selectedDay] ?? [];
                              _lastTappedDay = selectedDay;
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                          leftChevronVisible: false,
                          rightChevronVisible: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          headerTitleBuilder: (context, date) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PopupMenuButton<int>(
                                  onSelected: (month) {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year,
                                          month, _focusedDay.day);
                                    });
                                  },
                                  itemBuilder: (context) =>
                                      List.generate(12, (index) {
                                    final month = index + 1;
                                    return PopupMenuItem(
                                      value: month,
                                      child: Text(DateFormat.MMMM()
                                          .format(DateTime(2020, month))),
                                    );
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      DateFormat.MMMM().format(date),
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                PopupMenuButton<int>(
                                  onSelected: (year) {
                                    setState(() {
                                      _focusedDay = DateTime(year,
                                          _focusedDay.month, _focusedDay.day);
                                    });
                                  },
                                  itemBuilder: (context) =>
                                      List.generate(31, (index) {
                                    final year = 2020 + index;
                                    return PopupMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    );
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      DateFormat.y().format(date),
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              // Display up to 4 events.
                              final displayedEvents = events.take(4).toList();

                              return Positioned(
                                bottom:
                                    1, // Position the marker at the bottom of the cell
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                      displayedEvents.length, (index) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      width: 8.0,
                                      height: 8.0,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromARGB(255, 0, 0,
                                            255), // Set the color of the marker
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        eventLoader: _getEventsForDay,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(
                            color: Color.fromARGB(255, 255, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange,
                              width: 2.0,
                            ),
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendTextStyle: const TextStyle(),
                          defaultTextStyle: const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
                NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _initialChildSize = notification.extent;
                      if (_initialChildSize > 0.6 &&
                          _calendarFormat != CalendarFormat.week) {
                        _calendarFormat = CalendarFormat.week;
                      } else if (_initialChildSize <= 0.6 &&
                          _calendarFormat != CalendarFormat.month) {
                        _calendarFormat = CalendarFormat.month;
                      }
                    });
                    return true;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: _initialChildSize,
                    minChildSize: 0.45,
                    maxChildSize: _maxChildSize,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        color: Colors.black,
                        child: Column(
                          children: [
                            Container(
                              height: 30,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Container(
                                height: 5,
                                width: 40,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (_selectedDay != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  DateFormat.yMMMd().format(_selectedDay!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: _selectedEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _selectedEvents[index];
                                  final eventTime = event.isAllDay
                                      ? '終日'
                                      : '${event.startTime?.format(context) ?? '未設定'} - ${event.endTime?.format(context) ?? '未設定'}';
                                  return ListTile(
                                    title: Text(
                                      event.title,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      eventTime,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                    isThreeLine: false,
                                    onTap: () => _viewEventDetails(index),
                                    onLongPress: () =>
                                        _confirmDeleteEvent(index),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _showEventList
          ? null // Hide FAB while event list is displayed
          : FloatingActionButton(
              onPressed: () {
                if (_showNewButton) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => EventListScreen(
                              events: _events,
                            )),
                  );
                } else {
                  _addEvent();
                }
              },
              child: Icon(_showNewButton ? Icons.add : Icons.add),
            ),
    );
  }

  void _confirmDeleteEvent(int index) {
    final event = _selectedEvents[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'イベントの削除',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'このイベントを削除しますか？',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8.0),
              Text('タイトル: ${event.title}'),
              if (event.description.isNotEmpty) // Display only if details exist
                Text('詳細: ${event.description}'),
              Text(
                  '時間: ${event.isAllDay ? '終日' : '${event.startTime?.format(context) ?? '未設定'} - ${event.endTime?.format(context) ?? '未設定'}'}'),
              if (event.location != null) // If the location is set

                Text('場所: ${event.location}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedEvents.removeAt(index);
                  if (_selectedDay != null) {
                    _events[_selectedDay!] = _selectedEvents;
                  }
                  _saveEvents();
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

// ignore: unused_element
  void _sortEvents() {
    _selectedEvents.sort((a, b) {
      if (a.isAllDay && b.isAllDay) {
        return 0; // All-day events are in the same group, so do not sort
      } else if (a.isAllDay) {
        return -1; // Place all-day events before time-specific events
      } else if (b.isAllDay) {
        return 1; // Place all-day events after time-specific events
      } else {
        final aStartTime = a.startTime ?? const TimeOfDay(hour: 0, minute: 0);
        final bStartTime = b.startTime ?? const TimeOfDay(hour: 0, minute: 0);

        final startComparison = _compareTimeOfDay(aStartTime, bStartTime);
        if (startComparison != 0) {
          return startComparison;
        }

        // If start times are the same, sort by end time
        final aEndTime = a.endTime ?? const TimeOfDay(hour: 23, minute: 59);
        final bEndTime = b.endTime ?? const TimeOfDay(hour: 23, minute: 59);
        return _compareTimeOfDay(aEndTime, bEndTime);
      }
    });
  }

  void _addEvent() {
    final newEvent = Event(
      title: '',
      description: '',
      isAllDay: false,
    );
    showDialog(
      context: context,
      builder: (context) {
        return EventForm(
          event: newEvent,
          onSave: (event) {
            setState(() {
              if (_selectedDay != null) {
                _events.putIfAbsent(_selectedDay!, () => []).add(event);
                _sortEvents();
                _selectedEvents = _events[_selectedDay]!;
                _saveEvents();
              }
            });
          },
        );
      },
    );
  }

  void _viewEventDetails(int index) {
    final event = _selectedEvents[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.description.isNotEmpty)
                Text('詳細: ${event.description}'),
              Text(
                  '時間: ${event.isAllDay ? '終日' : '${event.startTime?.format(context) ?? '未設定'} - ${event.endTime?.format(context) ?? '未設定'}'}'),
              if (event.location != null) Text('場所: ${event.location}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editEvent(index);
              },
              child: const Text('編集'),
            ),
          ],
        );
      },
    );
  }

  void _editEvent(int index) {
    final event = _selectedEvents[index];
    showDialog(
      context: context,
      builder: (context) {
        return EventForm(
          event: event,
          onSave: (updatedEvent) {
            setState(() {
              if (_selectedDay != null) {
                _events[_selectedDay!]![index] = updatedEvent;
                _sortEvents();
                _selectedEvents = _events[_selectedDay]!;
                _saveEvents();
              }
            });
          },
        );
      },
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

  Event({
    required this.title,
    required this.description,
    required this.isAllDay,
    this.startTime,
    this.endTime,
    this.location,
  });
}

class EventForm extends StatefulWidget {
  final Event event;
  final void Function(Event) onSave;

  const EventForm({super.key, required this.event, required this.onSave});

  @override
  EventFormState createState() => EventFormState();
}

class EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isAllDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  // ignore: unused_field
  String? _location;
  String? _startTimeError;
  String? _endTimeError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _isAllDay = widget.event.isAllDay;
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _location = widget.event.location;
    _startTimeError = null;
    _endTimeError = null;
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay? initialTime,
      Function(TimeOfDay) onTimePicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimePicked(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('イベントを追加'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '詳細'),
              ),
              CheckboxListTile(
                title: const Text('終日'),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value ?? false;
                    if (_isAllDay) {
                      _startTime = null;
                      _endTime = null;
                      _startTimeError = null;
                      _endTimeError = null;
                    }
                  });
                },
              ),
              if (!_isAllDay) ...[
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('時間'),
                  subtitle: Text(
                    (_startTime != null && _endTime != null)
                        ? '${_startTime!.format(context)} - ${_endTime!.format(context)}'
                        : '選択してください',
                  ),
                  onTap: () async {
                    final pickedTimes = await _pickTimeRange(context);
                    if (pickedTimes != null) {
                      setState(() {
                        _startTime = pickedTimes[0];
                        _endTime = pickedTimes[1];
                        _startTimeError = null; // Reset error message
                        _endTimeError = null; // Reset error message
                      });
                    }
                  },
                ),
                if (_startTimeError != null || _endTimeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _startTimeError ?? _endTimeError ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('場所'),
                subtitle: Text(_location ?? 'ロケーションを追加'),
                onTap: () async {
                  final selectedLocation = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(
                        initialLocation: _location,
                      ),
                    ),
                  );
                  if (selectedLocation != null) {
                    setState(() {
                      _location = selectedLocation;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_isAllDay || (_startTime != null && _endTime != null)) {
                if (!_isAllDay) {
                  if (_startTime != null && _endTime != null) {
                    final updatedEvent = Event(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      isAllDay: _isAllDay,
                      startTime: _startTime,
                      endTime: _endTime,
                      location: _location,
                    );
                    widget.onSave(updatedEvent);
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      if (_startTime == null) {
                        _startTimeError = '時間を設定してください';
                      }
                    });
                  }
                } else {
                  final updatedEvent = Event(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    isAllDay: _isAllDay,
                    startTime: null,
                    endTime: null,
                    location: _location,
                  );
                  widget.onSave(updatedEvent);
                  Navigator.of(context).pop();
                }
              } else {
                setState(() {
                  if (_startTime == null) {
                    _startTimeError = '開始時間を設定してください';
                  }
                  if (_endTime == null) {
                    _endTimeError = '終了時間を設定してください';
                  }
                });
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

// Method to display a dialog for selecting a time range
  Future<List<TimeOfDay>?> _pickTimeRange(BuildContext context) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (startTime == null) return null;

    final endTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (endTime == null) return null;

    return [startTime, endTime];
  }
}
