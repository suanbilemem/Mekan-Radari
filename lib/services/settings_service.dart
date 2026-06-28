import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance =
      SettingsService._internal();

  SettingsService._internal();

  // -------------------------
  // KEYS
  // -------------------------
  static const String _darkModeKey =
      'dark_mode';
  static const String _soundKey =
      'notification_sound';
  static const String _vibrationKey =
      'notification_vibration';
  static const String _distanceKey =
      'trigger_distance';


  // ─────────────────────────────────────────
  // Ayar değiştiğinde background isolate'e haber ver.
  // ─────────────────────────────────────────
  void _notifyBackgroundService() {
    try {
      final service = FlutterBackgroundService();
      service.invoke('settingsChanged');
    } catch (e) {
      debugPrint('Background service sinyali gönderilemedi: $e');
    }
  }


  // -------------------------
  // DARK MODE
  // -------------------------
  Future<bool> getDarkMode() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getBool(
          _darkModeKey,
        ) ??
        true;
  }

  Future<void> setDarkMode(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(
      _darkModeKey,
      value,
    );
  }

  // -------------------------
  // BİLDİRİMLER (artık ayrı bir anahtar değil)
  // ─────────────────────────────────────────
  // "Bildirimler" ana switch'i kaldırıldı. Bildirim açık/kapalı
  // durumu artık Ses VE Titreşim'in ikisinin de OFF olup
  // olmamasından türetiliyor: ikisi de kapalıysa bildirim
  // hiç gösterilmez. notification_service.dart bu fonksiyonu
  // değişmeden çağırabiliyor, mantık burada merkezi.
  // -------------------------
  Future<bool> getNotifications() async {
    final sound = await getSound();
    final vibration = await getVibration();
    return sound || vibration;
  }

  // -------------------------
  // SOUND
  // -------------------------
  Future<bool> getSound() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getBool(
          _soundKey,
        ) ??
        true;
  }

  Future<void> setSound(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(
      _soundKey,
      value,
    );
    _notifyBackgroundService();
  }

  // -------------------------
  // VIBRATION
  // -------------------------
  Future<bool> getVibration() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getBool(
          _vibrationKey,
        ) ??
        true;
  }

  Future<void> setVibration(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(
      _vibrationKey,
      value,
    );
    _notifyBackgroundService();
  }

  // -------------------------
  // RADAR DISTANCE
  // -------------------------
  Future<double> getDistance() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getDouble(
          _distanceKey,
        ) ??
        500;
  }

  Future<void> setDistance(
    double value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();
    await prefs.setDouble(
      _distanceKey,
      value,
    );
    _notifyBackgroundService();
  }
}