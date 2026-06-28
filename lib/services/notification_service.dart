import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_service.dart';
import '../models/place_model.dart';
import 'map_launcher_service.dart';


class NotificationService {

  static final NotificationService instance =
      NotificationService._();

  NotificationService._();


  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();



  // ───────────────────────────────────────────────
  // 4 SABİT KANAL: ses x titreşim kombinasyonu kadar
  // Bunlar bir kere oluşturulur, asla yeniden oluşturulmaz.
  // Hangi bildirim gönderileceğinde sadece DOĞRU OLANI seçeriz.
  // ───────────────────────────────────────────────

  static const String _channelNameBase = 'Yer Radarı';

  String _channelId(bool sound, bool vibration) {
    final s = sound ? 1 : 0;
    final v = vibration ? 1 : 0;
    return 'yer_radari_s${s}_v$v';
  }

  String _channelLabel(bool sound, bool vibration) {
    final soundText = sound ? 'Sesli' : 'Sessiz';
    final vibrationText = vibration ? 'Titreşimli' : 'Titreşimsiz';
    return '$_channelNameBase ($soundText, $vibrationText)';
  }



  Future<bool> _notificationsEnabled() async {
    return await SettingsService.instance.getNotifications();
  }




  Future<void> initialize() async {

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings =
        InitializationSettings(android: androidSettings);

    final android =
        notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();


    // ─────────────────────────────────────────
    // ESKİ / BOZUK KANALLARI TEMİZLE (bir kerelik göç)
    // ─────────────────────────────────────────
    const legacyChannelIds = [
      'yer_radari_channel',
      'radar_channel_v3',
      'radar_channel_v4',
      'arrival_channel_v2',
      'save_channel_v3',
    ];

    for (final legacyId in legacyChannelIds) {
      try {
        await android?.deleteNotificationChannel(legacyId);
      } catch (e) {
        debugPrint('Eski kanal silinemedi ($legacyId): $e');
      }
    }


    // ─────────────────────────────────────────
    // 4 SABİT KANALI ÖNCEDEN OLUŞTUR
    // ─────────────────────────────────────────
    if (android != null) {
      for (final sound in [true, false]) {
        for (final vibration in [true, false]) {

          final id = _channelId(sound, vibration);

          final channel = AndroidNotificationChannel(
            id,
            _channelLabel(sound, vibration),
            description: 'Yer Radarı bildirimleri',
            importance: Importance.max,
            playSound: sound,
            enableVibration: vibration,
            vibrationPattern: vibration
                ? Int64List.fromList([0, 500, 500, 500])
                : null,
          );

          await android.createNotificationChannel(channel);

          debugPrint(
            '📡 KANAL OLUŞTURULDU: $id (ses=$sound, titreşim=$vibration)',
          );
        }
      }
    }


    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

  }



  // SES + TİTREŞİM AYARI

  Future<AndroidNotificationDetails> _getAndroidDetails() async {

    final prefs = await SharedPreferences.getInstance();

    final sound = prefs.getBool('notification_sound') ?? true;
    final vibration = prefs.getBool('notification_vibration') ?? true;

    debugPrint('🔊 SOUND AYARI: $sound');
    debugPrint('📳 TITREŞİM AYARI: $vibration');

    final selectedChannelId = _channelId(sound, vibration);
    final selectedChannelLabel = _channelLabel(sound, vibration);

    debugPrint('📡 SEÇİLEN KANAL: $selectedChannelId');

    return AndroidNotificationDetails(
      selectedChannelId,
      selectedChannelLabel,
      channelDescription: 'Yer Radarı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound,
      enableVibration: vibration,
      vibrationPattern: vibration
          ? Int64List.fromList([0, 500, 500, 500])
          : null,
    );

  }



  // VARIŞ BİLDİRİMİ

  Future<void> showArrivalNotification(PlaceModel place) async {

    if (!await _notificationsEnabled()) {
      return;
    }

    final androidDetails = await _getAndroidDetails();
    final details = NotificationDetails(android: androidDetails);

    await notifications.show(
      place.name.hashCode + 10000,
      '🎯 Hedefe vardınız',
      '${place.name} konumuna ulaştınız.',
      details,
      payload: _payloadForPlace(place),
    );

  }



  // YAKLAŞMA BİLDİRİMİ

  Future<void> showPlaceNotification(
    PlaceModel place,
    int distance,
  ) async {

    if (!await _notificationsEnabled()) {
      return;
    }

    final androidDetails = await _getAndroidDetails();
    final details = NotificationDetails(android: androidDetails);

    await notifications.show(
      place.name.hashCode + 20000,
      '📍 Yakınındasın',
      '${place.name} yaklaşık $distance metre uzaklıkta.',
      details,
      payload: _payloadForPlace(place),
    );

  }



  // KAYIT BİLDİRİMİ

  Future<void> showSavedNotification(PlaceModel place) async {

    if (!await _notificationsEnabled()) {
      return;
    }

    final androidDetails = await _getAndroidDetails();
    final details = NotificationDetails(android: androidDetails);

    await notifications.show(
      place.name.hashCode + 30000,
      '✅ Yer Kaydedildi',
      place.name,
      details,
      payload: _payloadForPlace(place),
    );

  }



  String _payloadForPlace(PlaceModel place) {
    return jsonEncode(place.toMap());
  }



  Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {

    final payload = response.payload;

    if (payload == null) {
      return;
    }

    await _openPayload(payload);

  }



  Future<void> _openPayload(String payload) async {

    final data = jsonDecode(payload) as Map<String, dynamic>;

    await MapLauncherService.openPlace(
      PlaceModel.fromMap(data),
    );

  }


}