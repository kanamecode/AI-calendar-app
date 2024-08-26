// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  // ignore: library_private_types_in_public_api
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  String? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  String? _apiKey; // API Key will be fetched from SharedPreferences
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('googleMapsApiKey'); // Check if key name is correct
    });
    print('Loaded API key: $_apiKey'); // Debug log to ensure key is loaded
  }

  Future<void> _searchPlaces(String query) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('API key is missing or empty');
      return;
    }

    // Print the API key for debugging purposes
    print('Using API key: $_apiKey');

    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$_apiKey',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final predictions = data['predictions'] as List;
      setState(() {
        _searchResults =
            predictions.map((e) => e['description'] as String).toList();
      });
    } else {
      print('Failed to load places: ${response.body}');
      throw Exception('Failed to load places');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('場所を選択'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedLocation);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '場所を検索',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchPlaces(value);
                } else {
                  setState(() {
                    _searchResults.clear();
                  });
                }
              },
            ),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return Container(
                    color: _selectedLocation == location
                        ? const Color.fromARGB(255, 53, 53, 53)
                        : Colors.transparent,
                    child: ListTile(
                      title: Text(location),
                      onTap: () {
                        setState(() {
                          _selectedLocation = location;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
