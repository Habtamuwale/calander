import 'package:flutter/material.dart';

class ScheduledEvent {
  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? recurrenceRule;
  final Color color;
  final bool hasReminder;
  final int? reminderMinutesBefore;
  final String description;
  final String timezone;
  final List<DateTime>? recurrenceExceptionDates;

  ScheduledEvent({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.description = '',
    this.recurrenceRule,
    this.color = Colors.indigo,
    this.hasReminder = false,
    this.reminderMinutesBefore = 15,
    this.timezone = 'UTC',
    this.recurrenceExceptionDates,
  });

  factory ScheduledEvent.fromJson(Map<String, dynamic> json) {
    return ScheduledEvent(
      id: json['id'] ?? '',
      subject: json['Subject'] ?? json['subject'] ?? 'No Title',
      startTime: DateTime.parse(json['StartTime'] ?? json['startTime']),
      endTime: DateTime.parse(json['EndTime'] ?? json['endTime']),
      location: json['Location'] ?? json['location'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      recurrenceRule: json['RecurrenceRule'] ?? json['recurrenceRule'],
      color: json['Color'] != null ? Color(int.parse(json['Color'])) : Colors.indigo,
      hasReminder: json['hasReminder'] ?? false,
      reminderMinutesBefore: json['reminderMinutesBefore'],
      timezone: json['timezone'] ?? 'UTC',
      recurrenceExceptionDates: json['recurrenceExceptionDates'] != null
          ? (json['recurrenceExceptionDates'] as List).map((d) => DateTime.parse(d)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Subject': subject,
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'Location': location,
      'Description': description,
      'RecurrenceRule': recurrenceRule,
      'Color': color.value.toString(),
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
      'timezone': timezone,
      'recurrenceExceptionDates': recurrenceExceptionDates?.map((d) => d.toIso8601String()).toList(),
    };
  }
  IconData get icon {
    final s = subject.toLowerCase();
    if (s.contains('gym') || s.contains('workout') || s.contains('exercise')) return Icons.fitness_center;
    if (s.contains('coffee') || s.contains('drink') || s.contains('tea')) return Icons.coffee;
    if (s.contains('meet') || s.contains('call') || s.contains('zoom')) return Icons.video_call;
    if (s.contains('doctor') || s.contains('hospital') || s.contains('med')) return Icons.medical_services;
    if (s.contains('eat') || s.contains('dinner') || s.contains('lunch') || s.contains('food')) return Icons.restaurant;
    if (s.contains('flight') || s.contains('travel') || s.contains('trip')) return Icons.flight;
    if (s.contains('study') || s.contains('class') || s.contains('learn')) return Icons.school;
    if (s.contains('shopping') || s.contains('buy') || s.contains('market')) return Icons.shopping_cart;
    if (s.contains('money') || s.contains('bank') || s.contains('pay')) return Icons.payments;
    return Icons.event;
  }
}
