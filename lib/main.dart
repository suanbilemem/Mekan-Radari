  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'dart:async';
  import 'package:receive_sharing_intent/receive_sharing_intent.dart';
  import 'package:geolocator/geolocator.dart' as geo;
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'package:geofence_service/geofence_service.dart';
  import 'database_helper.dart';

  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const YerRadariApp());
  }

  class YerRadariApp extends StatelessWidget {
    const YerRadariApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yer Radarı',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: const RadarHome(),
      );
    }
  }

    class RadarHome extends StatefulWidget {
      const RadarHome({super.key});

      @override
      State<RadarHome> createState() => _RadarHomeState();
    }

    class _RadarHomeState extends State<RadarHome> {
      // STREAM'LER
      StreamSubscription? _intentDataStreamSubscription;
      StreamSubscription<geo.Position>? _positionStream;

      // DURUM DEĞİŞKENLERİ
      String _gelenMetin = 'Bekleniyor...';
      double? _hedefEnlem;
      double? _hedefBoylam;
      String _hedefAdi = 'Paylaşılan Konum';

      double _secilenMesafe = 500;

      bool _takipAktif = false;
      bool _yukleniyor = false;

      // KAYITLI YERLER
      List<Map<String, dynamic>> _kayitliYerler = [];

    // BİLDİRİMLER
    final FlutterLocalNotificationsPlugin _notifications =
        FlutterLocalNotificationsPlugin();

    // GEOFENCE SERVICE
    final GeofenceService _geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 10000,
      statusChangeDelayMs: 5000,
      useActivityRecognition: false,
      allowMockLocations: false,
      printDevLog: true,
    );

    @override
    void initState() {
      super.initState();
      _sistemleriKur();
    }

    @override
    void dispose() {
      _positionStream?.cancel();
      _intentDataStreamSubscription?.cancel();
      _geofenceService.stop();
      super.dispose();
    }

    // BAŞLANGIÇ KURULUMU
    Future<void> _sistemleriKur() async {
      // Bildirim sistemi
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');

      await _notifications.initialize(
    settings: InitializationSettings(android: android),
      );

      // Android 13+ bildirim izni
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Konum izinleri
      await geo.Geolocator.requestPermission();

      // Veritabanındaki kayıtları yükle
      await _kayitliYerleriYukle();

      // Son kaydı geri yükle
      await _sonKaydiGeriYukle();

      // Paylaşım dinleme
      _intentDataStreamSubscription =
          ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (value.isNotEmpty) {
          final text = value.first.path;
          debugPrint('📥 PAYLAŞIM: $text');
          _linkiCozVeIsle(text);
        }
      });

      // Uygulama paylaşım ile açıldıysa
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        _linkiCozVeIsle(initial.first.path);
      }

      await ReceiveSharingIntent.instance.reset();}

    // KAYITLI YERLERİ YÜKLE
    Future<void> _kayitliYerleriYukle() async {
      final yerler = await DatabaseHelper.instance.getPlaces();
      if (!mounted) return;
      setState(() {
        _kayitliYerler = yerler;
      });
    }

    // SON KAYDI GERİ YÜKLE
    Future<void> _sonKaydiGeriYukle() async {
      if (_kayitliYerler.isEmpty) return;

      final son = _kayitliYerler.first;

      _hedefAdi = son['name'] ?? 'Paylaşılan Konum';
      _hedefEnlem = (son['latitude'] as num).toDouble();    _hedefBoylam = (son['longitude'] as num).toDouble();   _gelenMetin = '📂 Son kayıt yüklendi';

      if (_hedefEnlem != null && _hedefBoylam != null) {
        await _baslatGeofence(
          _hedefEnlem!,
          _hedefBoylam!,
          _hedefAdi,
        );
      }

      if (mounted) {
        setState(() {});
      }
    }

    // PAYLAŞILAN LİNKİ ÇÖZ
    Future<void> _linkiCozVeIsle(String metin) async {
      setState(() {
        _gelenMetin = metin;
        _yukleniyor = true;
        _hedefEnlem = null;
        _hedefBoylam = null;
      });

      try {
        final url = Uri.parse(
        'https://yer-radari-api.onrender.com/resolve',

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'text': metin}),
            )
            .timeout(const Duration(seconds: 10));
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['lat'] != null) {
          final double lat = (data['lat'] as num).toDouble();      final double lng = (data['lng'] as num).toDouble();       final String placeName =
              data['name']?.toString() ?? 'Paylaşılan Konum';

          // Ekranı güncelle
          setState(() {
            _hedefEnlem = lat;
            _hedefBoylam = lng;
            _hedefAdi = placeName;
            _yukleniyor = false;
            _gelenMetin = '✅ Konum çözüldü';
          });

          // Veritabanına kaydet
          await DatabaseHelper.instance.insertPlace({
        'name': placeName,
        'latitude': lat,
        'longitude': lng,
      });

          // Listeyi yenile
          await _kayitliYerleriYukle();
          // Geofence başlat
          await _baslatGeofence(lat, lng, placeName);
        } else {
          setState(() {
            _yukleniyor = false;
            _gelenMetin =
            _gelenMetin = 'Hata: ${data['error'] ?? 'Sunucu beklenmeyen bir yanıt döndürdü'}';
          });
        }
      } on TimeoutException {
        setState(() {
          _yukleniyor = false;
          _gelenMetin = '⏱️ Sunucuya ulaşılamadı (timeout)';
        });
      } catch (e) {
        debugPrint('🔥 HATA: $e');

        setState(() {
          _yukleniyor = false;
          _gelenMetin = 'Bağlantı hatası 😕 $e';
        });
      }
    }

    // ARKA PLAN GEOFENCE
    Future<void> _baslatGeofence(
      double lat,
      double lng,
      String placeName,
    ) async {
      try {
        await _geofenceService.stop();      _geofenceService.clearGeofenceList();
        _geofenceService.addGeofenceStatusChangeListener(
          (geofence, radius, status, location) async {
            debugPrint('📍 GEOFENCE STATUS: $status');
            if (status == GeofenceStatus.ENTER) {
        await _notifications.show(
        id: 999,
        title: '🎯 Hedefe Yaklaştın',
        body: '$placeName konumuna ${_secilenMesafe.toInt()} metre içinde girdin.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'geo_channel',
            'Geofence Notifications',
            channelDescription: 'Konum tabanlı uyarılar',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
            }
          },
        );

        final geofenceList = <Geofence>[
          Geofence(
            id: 'hedef_${DateTime.now().millisecondsSinceEpoch}',
            latitude: lat,
            longitude: lng,
            radius: [
              GeofenceRadius(
                id: 'alan',
                length: _secilenMesafe,
              ),
            ],
          ),
        ];
        await _geofenceService.start(geofenceList);

        debugPrint('✅ Geofence başlatıldı: $placeName');
      } catch (e) {
        debugPrint('🔥 Geofence hatası: $e');
      }
    }

    // GPS FALLBACK
    void _radariBaslat() {
    if (_hedefEnlem == null || _hedefBoylam == null) return;

    setState(() {
      _takipAktif = true;
    });

    _positionStream?.cancel();
    
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) async {
      if (!_takipAktif) return;

      final mesafe = geo.Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        _hedefEnlem!,
        _hedefBoylam!,
      );

      debugPrint('Mesafe: $mesafe');
      if (mesafe <= _secilenMesafe) {
        await _notifications.show(
          id: 100,
          title: '🎯 HEDEFE GELDİN!',
          body: '${_hedefAdi ?? "Konuma"} ulaştın.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'radar_channel',
              'Radar Uyarıları',
              channelDescription: 'Hedefe varış uyarıları',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

    // KAYIT SİL
    Future<void> _kaydiSil(int id) async {
      await DatabaseHelper.instance.deletePlace(id);
      await _kayitliYerleriYukle();
      if (_kayitliYerler.isEmpty) {
        setState(() {
          _hedefEnlem = null;
          _hedefBoylam = null;
          _hedefAdi = 'Paylaşılan Konum';
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yer Radarı'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _yukleniyor
                  ? const CircularProgressIndicator()
                  : Icon(
                      _hedefEnlem != null
                          ? Icons.check_circle
                          : Icons.radar,
                      size: 80,
                      color: _hedefEnlem != null
                          ? Colors.green
                          : Colors.grey,
                    ),

              const SizedBox(height: 20),

              Text(
                _hedefEnlem != null
                    ? '✅ $_hedefAdi'
                    : 'Google Haritalar’dan Yer Paylaşın',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              if (_hedefEnlem != null) ...[
                const SizedBox(height: 10),
                Text('📍 $_hedefEnlem, $_hedefBoylam'),
              ],

              const SizedBox(height: 30),

              Slider(
                value: _secilenMesafe,
                min: 100,
                max: 2000,
                divisions: 19,
                label: '${_secilenMesafe.toInt()} m',
                onChanged: (v) {
                  setState(() {
                    _secilenMesafe = v;
                  });
                },
              ),

              Text(
                'Uyarı Mesafesi: ${_secilenMesafe.toInt()} m',
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed:
                    (_hedefEnlem == null || _takipAktif)
                        ? null
                        : _radariBaslat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  _takipAktif
                      ? 'Takip Ediliyor...'
                      : 'Radarı Başlat (GPS)',
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Son Veri:\n$_gelenMetin',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kayıtlı Yerler',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_kayitliYerler.isEmpty)
                const Text('Henüz kayıtlı yer yok.')            else
                ..._kayitliYerler.map((yer) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        yer['name'] ?? 'Paylaşılan Konum',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${yer['latitude']}, ${yer['longitude']}',
                      ),
                      onTap: () async {
                        final lat =
                            (yer['latitude'] as num).toDouble();
                        final lng =
                            (yer['longitude'] as num).toDouble();
                        final name =
                            yer['name'] ?? 'Paylaşılan Konum';

                        setState(() {
                          _hedefEnlem = lat;
                          _hedefBoylam = lng;
                          _hedefAdi = name;
                          _gelenMetin = '📂 Kayıt seçildi';
                        });

                        await _baslatGeofence(lat, lng, name);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _kaydiSil(yer['id']),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    }
  }