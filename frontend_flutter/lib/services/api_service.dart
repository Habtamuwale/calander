import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5000/api/events'; 
  final AuthService _auth = AuthService();

  // Initial mock data
  static final List<ScheduledEvent> _initialMockEvents = [
    ScheduledEvent(
      id: '1',
      subject: 'Welcome to Vibrant Scheduler!',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      location: 'Your App!',
      color: Colors.indigo,
      hasReminder: true,
      reminderMinutesBefore: 15,
      timezone: 'UTC',
    ),
  ];

  Future<List<ScheduledEvent>> getEvents() async {
    final token = await _auth.getToken();
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      final String? eventsJson = prefs.getString('demo_events');
      if (eventsJson == null) return _initialMockEvents;
      
      List<dynamic> body = jsonDecode(eventsJson);
      return body.map((dynamic item) => ScheduledEvent.fromJson(item)).toList();
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => ScheduledEvent.fromJson(item)).toList();
      } else {
        throw "Failed to load events";
      }
    } catch (e) {
       // Fallback for connectivity issues in demo if needed
       return [];
    }
  }

  Future<void> _saveDemoEvents(List<ScheduledEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final String eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString('demo_events', eventsJson);
  }

  Future<ScheduledEvent> createEvent(ScheduledEvent event) async {
    final token = await _auth.getToken();
    if (token == null) {
      final events = await getEvents();
      final newEvent = ScheduledEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: event.subject,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        color: event.color,
        recurrenceRule: event.recurrenceRule,
        hasReminder: event.hasReminder,
        reminderMinutesBefore: event.reminderMinutesBefore,
        timezone: event.timezone,
      );
      events.add(newEvent);
      await _saveDemoEvents(events);
      return newEvent;
    }
    
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 201) {
      return ScheduledEvent.fromJson(jsonDecode(response.body));
    } else {
      throw "Failed to create event";
    }
  }

  Future<void> updateEvent(ScheduledEvent event) async {
    final token = await _auth.getToken();
    if (token == null) {
      final events = await getEvents();
      final index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        events[index] = event;
        await _saveDemoEvents(events);
      }
      return;
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/${event.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode != 200) {
      throw "Failed to update event";
    }
  }

  Future<void> deleteEvent(String id) async {
    final token = await _auth.getToken();
    if (token == null) {
      final events = await getEvents();
      events.removeWhere((e) => e.id == id);
      await _saveDemoEvents(events);
      return;
    }
    
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw "Failed to delete event";
    }
  }
}
