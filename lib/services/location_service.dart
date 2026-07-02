import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../database_helper.dart';
import '../models/place_model.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  final Map<int, bool> _notificationSent = {};
  final Map<int, bool> _arrivedSent = {};

  // ─────────────────────────────────────────
  // YER BAZLI KONTROL ZAMANI
  // Her yerin son ne zaman kontrol edildiği burada tutulur.
  // Genel döngü en sık gereken aralıkla çalışır (GPS okuması
  // paylaşılır, tek seferde alınır), ama her yer SADECE kendi
  // aralığı geçtiyse gerçekten hesaplanır/loglanır/bildirilir.
  // Böylece 2km uzaktaki bir yer, 50m'deki bir yer yüzünden
  // her 5 saniyede bir gereksiz kontrol edilmez.
  // ─────────────────────────────────────────

  final Map<int, DateTime> _lastCheckedAt = {};

  static const double _farThreshold = 1000;
  static const double _arrivalZone = 25;

  static const Duration _farInterval = Duration(seconds: 60);
  static const Duration _midInterval = Duration(seconds: 15);
  static const Duration _nearInterval = Duration(seconds: 5);
  static const Duration _arrivalInterval = Duration(seconds: 2);

  Timer? _radarTimer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) {
      debugPrint('Radar zaten çalışıyor');
      return;
    }

    _isRunning = true;
    _runCycle();
  }

  void stop() {
    _isRunning = false;
    _radarTimer?.cancel();
    _radarTimer = null;
  }

  Future<void> _runCycle() async {
    if (!_isRunning) return;

    final nextInterval = await checkPlaces();

    debugPrint(
      '⏱️ Bir sonraki kontrol: ${nextInterval.inSeconds} saniye sonra',
    );

    _radarTimer = Timer(nextInterval, _runCycle);
  }

  // Tüm yerleri gezer, ama her yer İÇİN kendi aralığı geçmediyse
  // o yeri atlar (hesaplama/log/bildirim yapmaz). Genel döngünün
  // bir sonraki çalışma süresi, hangi yerin en kısa aralığa
  // sahip olduğuna göre belirlenir.
  Future<Duration> checkPlaces() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final places = await DatabaseHelper.instance.getPlaces();

      final triggerDistance = await SettingsService.instance.getDistance();
      final now = DateTime.now();

      Duration shortestNextInterval = _farInterval;

      for (final place in places) {
        final placeId = place.id;
        if (placeId == null) continue;

        // Bu yerin tahmini mesafesine göre gereken aralığı,
        // SON BİLİNEN kontrolden hesapla (henüz bu turda
        // ölçmedik, o yüzden son ölçümü referans alıyoruz).
        final lastChecked = _lastCheckedAt[placeId];
        final estimatedDistance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          place.lat,
          place.lng,
        );

        final requiredInterval = _intervalFor(estimatedDistance, triggerDistance);

        final dueForCheck = lastChecked == null ||
            now.difference(lastChecked) >= requiredInterval;

        if (dueForCheck) {
          await _checkDistance(position, place, estimatedDistance);
          _lastCheckedAt[placeId] = now;
        }

        if (requiredInterval < shortestNextInterval) {
          shortestNextInterval = requiredInterval;
        }
      }

      return shortestNextInterval;
    } catch (e) {
      debugPrint('❌ checkPlaces HATA: $e');
      return _farInterval;
    }
  }

  Duration _intervalFor(double distance, double triggerDistance) {
    if (distance <= _arrivalZone) {
      return _arrivalInterval;
    }
    if (distance <= triggerDistance) {
      return _nearInterval;
    }
    if (distance <= _farThreshold) {
      return _midInterval;
    }
    return _farInterval;
  }

  Future<void> _checkDistance(
    Position position,
    PlaceModel place,
    double distance,
  ) async {
    try {
      debugPrint('📏 ${place.name}: ${distance.toInt()} metre');

      final notificationsEnabled =
          await SettingsService.instance.getNotifications();

      if (!notificationsEnabled) {
        return;
      }

      final triggerDistance = await SettingsService.instance.getDistance();
      const arrivalDistance = 20;

      // YAKLAŞTIN
      if (distance <= triggerDistance && distance > arrivalDistance) {
        if (_notificationSent[place.id] != true) {
          _notificationSent[place.id!] = true;

          await NotificationService.instance.showPlaceNotification(
            place,
            distance.toInt(),
          );
        }
      }
      // VARDIN
      else if (distance <= arrivalDistance) {
        if (_arrivedSent[place.id] != true) {
          _arrivedSent[place.id!] = true;

          await NotificationService.instance.showArrivalNotification(place);
        }
      }
      // UZAKLAŞINCA RESET
      else if (distance > triggerDistance + 200) {
        _notificationSent[place.id!] = false;
        _arrivedSent[place.id!] = false;
      }
    } catch (e) {
      debugPrint('❌ Mesafe kontrol hatası: $e');
    }
  }

  // ─────────────────────────────────────────
  // TALEP ÜZERİNE RADAR (On-Demand Radar)
  // Ana ekrandaki dairesel butona basıldığında çağrılır.
  // Arka plan döngüsüyle hiçbir ilişkisi yok — tek seferlik,
  // bağımsız bir GPS okuması yapar ve en yakın 5 yeri
  // mesafeye göre sıralı döndürür. Hiçbir bildirim göndermez,
  // hiçbir kilit/state güncellemez — sadece okur ve sıralar.
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> getNearestFive() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final places = await DatabaseHelper.instance.getPlaces();

      if (places.isEmpty) {
        return [];
      }

      final withDistance = places.map((place) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          place.lat,
          place.lng,
        );
        return MapEntry(place, distance);
      }).toList();

      withDistance.sort((a, b) => a.value.compareTo(b.value));

      return withDistance.take(5).map((entry) => entry.key).toList();
    } catch (e) {
      debugPrint('❌ getNearestFive HATA: $e');
      return [];
    }
  }
}