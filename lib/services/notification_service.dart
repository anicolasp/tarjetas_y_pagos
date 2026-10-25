import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// The 10-year database: much lighter to load at startup than the full one.
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/notification_plan.dart';

/// Local reminders (cut, payment deadline, debt due). Nothing leaves the
/// phone.
abstract interface class NotificationService {
  /// Sets up the plugin. [onTap] gets the route of a tapped notification.
  /// Returns the route of the notification that launched the app, if any.
  Future<String?> init({required void Function(String route) onTap});

  /// Asks for permission (Android 13+). True when notifications may show.
  Future<bool> requestPermission();

  /// Cancels every reminder and schedules [plan] instead.
  Future<void> replaceAll(List<PlannedNotification> plan);

  Future<void> cancelAll();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Recordatorios',
      channelDescription: 'Corte, fecha límite de pago y deudas por vencer',
    ),
  );

  @override
  Future<String?> init({required void Function(String route) onTap}) async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // Unknown zone name: use the device's current offset, so 9:00 stays
      // 9:00 local (UTC would send it at 5:00 in Santo Domingo).
      tz.setLocalLocation(
        tz.Location('Device', [tz.minTime], [0], [
          tz.TimeZone(
            DateTime.now().timeZoneOffset,
            isDst: false,
            abbreviation: 'LOCAL',
          ),
        ]),
      );
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload case final route?) onTap(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp ?? false
        ? launch!.notificationResponse?.payload
        : null;
  }

  @override
  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    await _plugin.cancelAll();
    for (final n in plan) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime(
          tz.local,
          n.at.year,
          n.at.month,
          n.at.day,
          n.at.hour,
          n.at.minute,
        ),
        notificationDetails: _details,
        // Inexact: no exact-alarm permission needed; a 9:00 reminder may
        // arrive a few minutes late.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: n.route,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
