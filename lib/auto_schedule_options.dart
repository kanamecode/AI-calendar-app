import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'location_picker_screen.dart';
import 'schedule_planner.dart';

// ignore: use_key_in_widget_constructors
class AutoScheduleSettingsScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AutoScheduleSettingsScreenState createState() =>
      _AutoScheduleSettingsScreenState();
}

class _AutoScheduleSettingsScreenState
    extends State<AutoScheduleSettingsScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDetailsController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  int _selectedHours = 0;
  int _selectedMinutes = 0;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
        _periodController.text =
            '${DateFormat('yyyy/MM/dd').format(picked.start)} - ${DateFormat('yyyy/MM/dd').format(picked.end)}';
      });
    }
  }

  Future<void> _selectLocation(BuildContext context) async {
    final String? selectedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerScreen(initialLocation: _locationController.text),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _locationController.text = selectedLocation;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final Map<String, int>? selectedTime = await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        int hours = _selectedHours;
        int minutes = _selectedMinutes;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('イベントの継続時間'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: hours,
                          onChanged: (int? newValue) {
                            setState(() {
                              hours = newValue!;
                            });
                          },
                          items: List.generate(24, (index) {
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text('$index 時間'),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<int>(
                          value: minutes,
                          onChanged: (int? newValue) {
                            setState(() {
                              minutes = newValue!;
                            });
                          },
                          items: List.generate(60, (index) {
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text('$index 分'),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop({'hours': hours, 'minutes': minutes});
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _selectedHours = selectedTime['hours']!;
        _selectedMinutes = selectedTime['minutes']!;
      });
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDetailsController.dispose();
    _periodController.dispose();
    _commentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double iconTextSpacing = 8.0;
    const double itemSpacing = 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI自動イベント作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'イベント名',
              ),
            ),
            const SizedBox(height: itemSpacing),
            TextFormField(
              controller: _eventDetailsController,
              decoration: const InputDecoration(
                labelText: 'イベント詳細',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: itemSpacing),
            GestureDetector(
              onTap: () => _selectDateRange(context),
              child: AbsorbPointer(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: iconTextSpacing),
                    Expanded(
                      child: TextFormField(
                        controller: _periodController,
                        decoration: const InputDecoration(
                          labelText: '期間',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: itemSpacing),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time),
                    const SizedBox(width: iconTextSpacing),
                    Expanded(
                      child: Text(
                        '$_selectedHours 時間 $_selectedMinutes 分',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: itemSpacing),
            GestureDetector(
              onTap: () => _selectLocation(context),
              child: AbsorbPointer(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on),
                    const SizedBox(width: iconTextSpacing),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: '場所',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: itemSpacing),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'テキストで予定を入力 または 追加の指示',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '例：午前中に入れて\n　　〇〇日は除く',
                        border: InputBorder.none,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SchedulePlannerScreen(
                      startDate: _selectedStartDate ?? DateTime.now(),
                      endDate: _selectedEndDate ?? DateTime.now(),
                      eventName: _eventNameController.text,
                      period: _periodController.text,
                      eventDetails: _eventDetailsController.text,
                      location: _locationController.text,
                      timeRange: '$_selectedHours 時間 $_selectedMinutes 分',
                      comment: _commentController.text,
                      selectedHours: _selectedHours,
                      selectedMinutes: _selectedMinutes,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                backgroundColor: const Color.fromARGB(255, 191, 124, 0),
              ),
              child: const Text(
                'AI自動作成',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
