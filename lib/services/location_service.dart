import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../database_helper.dart';
import '../models/place_model.dart';
import 'notification_service.dart';

class LocationService {
  static final LocationService instance = LocationService._();

  LocationService._();

  final Map<int, bool> _notificationSent = {};

  Future<void> checkPlaces() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('📍 BG KONUM: ${position.latitude}, ${position.longitude}');

      final places = await DatabaseHelper.instance.getPlaces();

      debugPrint('📦 KAYITLI YER SAYISI: ${places.length}');

      for (final place in places) {
        await _checkDistance(position, place);
      }
    } catch (e) {
      debugPrint('❌ checkPlaces HATA: $e');
    }
  }

  Future<void> _checkDistance(Position position, PlaceModel place) async {
    try {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.lat,
        place.lng,
      );

      debugPrint('📏 ${place.name}: ${distance.toInt()} metre');

      const triggerDistance = 500;

      if (distance <= triggerDistance) {
        if (_notificationSent[place.id] == true) {
          debugPrint('⛔ Bildirim daha önce gönderilmiş');
          return;
        }

        _notificationSent[place.id!] = true;

        debugPrint('🔔 Bildirim gönderiliyor: ${place.name}');

        await NotificationService.instance.showPlaceNotification(
          place,
          distance.toInt(),
        );

        debugPrint('✅ Bildirim gönderildi');
      } else if (distance > 700) {
        _notificationSent[place.id!] = false;

        debugPrint('♻️ Bildirim kilidi sıfırlandı');
      }
    } catch (e) {
      debugPrint('❌ Mesafe kontrol hatası: $e');
    }
  }
}
