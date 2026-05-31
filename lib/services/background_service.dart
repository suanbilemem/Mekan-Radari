import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'location_service.dart';
import '../database_helper.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        autoStartOnBoot: true,
        foregroundServiceNotificationId: 999,
        initialNotificationTitle: 'Yer Radarı',
        initialNotificationContent: 'Konum izleniyor',
      ),
      iosConfiguration: IosConfiguration(),
    );

    service.startService();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  debugPrint('🚀 Background Service Başladı');

  Timer.periodic(
    const Duration(seconds: 30),
    (timer) async {
      try {
        debugPrint('🔄 Background kontrol başladı');

        final places =
            await DatabaseHelper.instance.getPlaces();

        debugPrint(
          '📦 Kayıtlı yer sayısı: ${places.length}',
        );

        await LocationService.instance
            .checkPlaces();

        debugPrint(
          '✅ Konum kontrolü tamamlandı',
        );
      } catch (e) {
        debugPrint(
          '❌ Background hata: $e',
        );
      }
    },
  );
}