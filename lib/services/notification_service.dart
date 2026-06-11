import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/place_model.dart';
import 'map_launcher_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final launchDetails = await notifications.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;

    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchResponse?.payload != null) {
      await _openPayload(launchResponse!.payload!);
    }
  }

  Future<void> showPlaceNotification(PlaceModel place, int distance) async {
    const androidDetails = AndroidNotificationDetails(
      'save_channel',
      'Radar Bildirimleri',
      channelDescription: 'Yer kaydedildi bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await notifications.show(
      place.name.hashCode,
      'Yakınındasın',
      '${place.name} yaklaşık $distance metre uzaklıkta.',
      details,
      payload: _payloadForPlace(place),
    );
  }

  Future<void> showSavedNotification(PlaceModel place) async {
    const androidDetails = AndroidNotificationDetails(
      'save_channel',
      'Kayıt Bildirimleri',
      channelDescription: 'Yer kaydedildi bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await notifications.show(
      place.name.hashCode,
      'Yer Kaydedildi',
      place.name,
      details,
      payload: _payloadForPlace(place),
    );
  }

  String _payloadForPlace(PlaceModel place) {
    return jsonEncode(place.toMap());
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;

    if (payload == null) return;

    await _openPayload(payload);
  }

  Future<void> _openPayload(String payload) async {
    final data = jsonDecode(payload) as Map<String, dynamic>;

    await MapLauncherService.openPlace(PlaceModel.fromMap(data));
  }
}
