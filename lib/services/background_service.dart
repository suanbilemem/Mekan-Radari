import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    if (await service.isRunning()) {
      debugPrint('Background service zaten çalışıyor');
      return;
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        autoStartOnBoot: true,

        // ─────────────────────────────────────────
        // ÖNEMLİ: Bu kalıcı bildirim Android tarafından
        // ZORUNLU tutulur (foreground service kuralı).
        // Kapatamayız ama SESSİZ ve TİTREŞİMSİZ bir
        // kanala alabiliriz — kullanıcının ayarlarını
        // etkilemeden, "Yakınındasın" ile karışmasın.
        // ─────────────────────────────────────────
        foregroundServiceNotificationId: 999,
        foregroundServiceTypes: [AndroidForegroundType.location],
        initialNotificationTitle: 'Yer Radarı',
        initialNotificationContent: 'Konum izleniyor',
      ),
      iosConfiguration: IosConfiguration(),
    );

    await service.startService();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  debugPrint('🚀 Background Service Başladı');

  // ─────────────────────────────────────────
  // ÖNEMLİ: Background isolate, ana uygulama isolate'inden
  // TAMAMEN AYRI bir bellek alanında çalışır. notifications
  // plugin'i bu isolate'te de kendi başına initialize edilmeli,
  // yoksa channel seçimi yapılsa bile bildirim sistemi bunu
  // tanımayıp varsayılan (genelde titreşimli) davranışa düşebilir.
  //
  // KRİTİK: Bu çağrı AWAIT edilmeli. initialize() içinde 4 kanalın
  // her biri için sil+oluştur işlemi yapılıyor (~13 async adım).
  // Eğer bu tamamlanmadan radar başlarsa, bir bildirim kanal henüz
  // oluşturulma sürecinin ORTASINDAYKEN gönderilebilir ve Android
  // yanlış/varsayılan (titreşimli) bir davranışa düşebilir.
  // ─────────────────────────────────────────
  try {
    await NotificationService.instance.initialize();
    debugPrint('✅ Background isolate: NotificationService hazır');
  } catch (e) {
    debugPrint('❌ Background isolate initialize hatası: $e');
  }

  // ─────────────────────────────────────────
  // Ana uygulamadan ayar değişikliği sinyali geldiğinde
  // hemen bir kontrol turu yapılır (yeni ayarla).
  // ─────────────────────────────────────────
  service.on('settingsChanged').listen((event) async {
    debugPrint('🔔 Ayar değişikliği sinyali alındı, anlık kontrol yapılıyor');
    try {
      await LocationService.instance.checkPlaces();
    } catch (e) {
      debugPrint('❌ Ayar değişikliği sonrası kontrol hatası: $e');
    }
  });

  // ─────────────────────────────────────────
  // TEK RADAR DÖNGÜSÜ
  // Artık burada Timer.periodic(30sn) yok. LocationService
  // kendi kendini dinamik aralıklarla yeniden zamanlıyor:
  // uzak yerler için seyrek, yaklaşma bölgesinde sık,
  // vardın bölgesinde çok sık kontrol ediyor. Çakışan iki
  // paralel timer yerine tek, kendini ayarlayan bir döngü var.
  // ─────────────────────────────────────────
  LocationService.instance.start();
}