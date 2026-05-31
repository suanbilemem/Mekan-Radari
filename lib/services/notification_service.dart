import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance =
      NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin
      notifications =
          FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings =
        InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(
      settings,
    );
  }

  Future<void> showPlaceNotification(
    String placeName,
    int distance,
  ) async {
    const androidDetails =
        AndroidNotificationDetails(
      'radar_channel',
      'Radar Bildirimleri',
      channelDescription:
          'Yakındaki kayıtlı yerler',

      importance: Importance.max,
      priority: Priority.high,
    );

    const details =
        NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      placeName.hashCode,
      '📍 Yakınındasın',
      '$placeName yaklaşık $distance metre uzaklıkta.',
      details,
    );
  }
}