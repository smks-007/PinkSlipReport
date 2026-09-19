import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  static const String webClientId =
      '674621045170-7ke59728ij1f3e6mg49bskue6scg9v90.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? webClientId : null,
    scopes: <String>[
      cal.CalendarApi.calendarEventsReadonlyScope,
      cal.CalendarApi.calendarEventsScope,
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Trigger Google Sign-In
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign out from Google account
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }

  /// Get authenticated CalendarApi client
  Future<cal.CalendarApi?> getCalendarApi() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) return null;

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) return null;

      return cal.CalendarApi(authClient);
    } catch (e) {
      debugPrint('Error obtaining Calendar API client: $e');
      return null;
    }
  }

  /// Fetch upcoming events from primary calendar
  Future<List<cal.Event>> getUpcomingEvents({
    int maxResults = 20,
    DateTime? timeMin,
  }) async {
    final api = await getCalendarApi();
    if (api == null) {
      throw Exception('Unable to authenticate with Google Calendar.');
    }

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startTime = (timeMin ?? startOfToday).toUtc();
      final events = await api.events.list(
        'primary',
        timeMin: startTime,
        maxResults: maxResults,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      debugPrint('Error fetching events from Google Calendar: $e');
      rethrow;
    }
  }

  /// Add an event to the primary calendar
  Future<cal.Event?> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    final api = await getCalendarApi();
    if (api == null) return null;

    try {
      final newEvent = cal.Event(
        summary: title,
        description: description,
        location: location,
        start: cal.EventDateTime(dateTime: start.toUtc(), timeZone: 'UTC'),
        end: cal.EventDateTime(dateTime: end.toUtc(), timeZone: 'UTC'),
      );

      return await api.events.insert(newEvent, 'primary');
    } catch (e) {
      debugPrint('Error adding event to Google Calendar: $e');
      rethrow;
    }
  }
}
