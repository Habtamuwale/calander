import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

/// A simple HTTP client that adds Google authentication headers
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      calendar.CalendarApi.calendarEventsScope,
    ],
  );

  Future<void> syncEventToGoogle(ScheduledEvent event) async {
    try {
      debugPrint('Initiating Google Sign-In...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        debugPrint('Google Sign-In was cancelled.');
        return;
      }

      debugPrint('Fetching authenticated HTTP client...');
      // Replace authenticatedClient() with authHeaders
      final Map<String, String> authHeaders = await account.authHeaders;
      final client = GoogleHttpClient(authHeaders);

      final api = calendar.CalendarApi(client);
      
      final googleEvent = calendar.Event()
        ..summary = event.subject
        ..location = event.location
        ..start = (calendar.EventDateTime()
          ..dateTime = event.startTime
          ..timeZone = event.timezone)
        ..end = (calendar.EventDateTime()
          ..dateTime = event.endTime
          ..timeZone = event.timezone);

      if (event.recurrenceRule != null) {
        googleEvent.recurrence = ['RRULE:${event.recurrenceRule}'];
      }

      debugPrint('Inserting event into Google Calendar...');
      await api.events.insert(googleEvent, 'primary');
      debugPrint('Sync successful!');
      
    } catch (e) {
      debugPrint('Google Calendar Sync Error: $e');
    }
  }
}
