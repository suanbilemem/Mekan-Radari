import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  // STREAM
  StreamSubscription? _intentDataStreamSubscription;
  StreamSubscription<geo.Position>? _positionStream;

  // DURUM
  String _gelenMetin = 'Bekleniyor...';

  double? _hedefEnlem;
  double? _hedefBoylam;

  String _hedefAdi = 'Paylaşılan Konum';

  double _secilenMesafe = 500;

  bool _takipAktif = false;
  bool _yukleniyor = false;

  // KAYITLI YERLER
  List<Map<String, dynamic>> _kayitliYerler = [];

  // BİLDİRİM
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _sistemleriKur();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  // BAŞLANGIÇ
  Future<void> _sistemleriKur() async {

    // Bildirim
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _notifications.initialize(
  settings: const InitializationSettings(
        android: android,
      ),
    );

    // Bildirim izni
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Konum izni
    await geo.Geolocator.requestPermission();

    // Verileri yükle
    await _kayitliYerleriYukle();

    // PAYLAŞIM DİNLE
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance
            .getMediaStream()
            .listen((value) {

      if (value.isNotEmpty) {

        final text =
            value.first.path.toString();

        debugPrint('📥 PAYLAŞIM: $text');

        _linkiCozVeIsle(text);
      }
    });

    // Uygulama paylaşım ile açıldıysa
    final initial =
        await ReceiveSharingIntent.instance
            .getInitialMedia();

    if (initial.isNotEmpty) {

      _linkiCozVeIsle(
        initial.first.path.toString(),
      );
    }

    await ReceiveSharingIntent.instance.reset();
  }

  // KAYITLI YERLERİ YÜKLE
  Future<void> _kayitliYerleriYukle() async {

    final yerler =
        await DatabaseHelper.instance.getPlaces();

    if (!mounted) return;

    setState(() {
      _kayitliYerler = yerler;
    });
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
        'https://mekan-radari.onrender.com/resolve',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'text': metin,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
          );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['lat'] != null) {

        final double lat =
            (data['lat'] as num)
                .toDouble();

        final double lng =
            (data['lng'] as num)
                .toDouble();

        final String placeName =
            data['name']?.toString() ??
                'Paylaşılan Konum';

        // SADECE EKRANI GÜNCELLE
        setState(() {

          _hedefEnlem = lat;
          _hedefBoylam = lng;

          _hedefAdi = placeName;

          _yukleniyor = false;

          _gelenMetin =
              '✅ Konum hazır';
        });

      } else {

        setState(() {

          _yukleniyor = false;

          _gelenMetin =
              'Hata: ${data['error'] ?? 'Sunucu hatası'}';
        });
      }

    } on TimeoutException {

      setState(() {

        _yukleniyor = false;

        _gelenMetin =
            '⏱️ Sunucuya ulaşılamadı';
      });

    } catch (e) {

      debugPrint('🔥 HATA: $e');

      setState(() {

        _yukleniyor = false;

        _gelenMetin =
            'Bağlantı hatası 😕 $e';
      });
    }
  }

  // KAYDET
  Future<void> _kaydetVeTakibeAl() async {

    if (_hedefEnlem == null ||
        _hedefBoylam == null) {
      return;
    }

    await DatabaseHelper.instance.insertPlace({

      'name': _hedefAdi,

      'latitude': _hedefEnlem,

      'longitude': _hedefBoylam,
    });

    await _kayitliYerleriYukle();

    setState(() {

      _gelenMetin =
          '✅ Kaydedildi';
    });
  }

  // RADAR
  void _radariBaslat() {

    setState(() {

      _takipAktif = true;
    });

    _positionStream?.cancel();

    _positionStream =
        geo.Geolocator.getPositionStream(
      locationSettings:
          const geo.LocationSettings(
        accuracy:
            geo.LocationAccuracy.high,

        distanceFilter: 25,
      ),
    ).listen((p) async {

      if (!_takipAktif) return;

      for (final yer in _kayitliYerler) {

        final double lat =
            (yer['latitude'] as num)
                .toDouble();

        final double lng =
            (yer['longitude'] as num)
                .toDouble();

        final String name =
            yer['name'] ??
                'Kayıtlı Yer';

        final uzaklik =
            geo.Geolocator.distanceBetween(
          p.latitude,
          p.longitude,
          lat,
          lng,
        );

        // 5 KM DIŞIYSA BAKMA
        if (uzaklik > 5000) {
          continue;
        }

        debugPrint(
            '📍 $name uzaklık: $uzaklik');

        // ALANA GİRDİYSE
        if (uzaklik <= _secilenMesafe) {

          await _notifications.show(

            id: yer['id'],

            title: '🎯 Hedefe Yaklaştın',

            body:
                '$name konumuna '
                '${_secilenMesafe.toInt()} metre kaldı.',

            notificationDetails:
                const NotificationDetails(

              android:
                  AndroidNotificationDetails(

                'radar_channel',

                'Radar Uyarıları',

                channelDescription:
                    'Yakındaki hedef bildirimleri',

                importance:
                    Importance.max,

                priority:
                    Priority.high,
              ),
            ),
          );
        }
      }
    });
  }

  // KAYIT SİL
  Future<void> _kaydiSil(int id) async {

    await DatabaseHelper.instance
        .deletePlace(id);

    await _kayitliYerleriYukle();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Yer Radarı',
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            _yukleniyor
                ? const CircularProgressIndicator()
                : Icon(

                    _hedefEnlem != null
                        ? Icons.check_circle
                        : Icons.radar,

                    size: 80,

                    color:
                        _hedefEnlem != null
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
                fontWeight:
                    FontWeight.bold,
              ),

              textAlign:
                  TextAlign.center,
            ),

            // KAYDET BUTONU
            if (_hedefEnlem != null) ...[

              const SizedBox(height: 20),

              ElevatedButton.icon(

                onPressed:
                    _kaydetVeTakibeAl,

                icon: const Icon(
                  Icons.bookmark,
                ),

                label: const Text(
                  'Kaydet',
                ),

                style:
                    ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    56,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            Slider(

              value: _secilenMesafe,

              min: 100,

              max: 2000,

              divisions: 19,

              label:
                  '${_secilenMesafe.toInt()} m',

              onChanged: (v) {

                setState(() {

                  _secilenMesafe = v;
                });
              },
            ),

            Text(

              'Uyarı Mesafesi: '
              '${_secilenMesafe.toInt()} m',

              style:
                  const TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed:
                  _takipAktif
                      ? null
                      : _radariBaslat,

              style:
                  ElevatedButton.styleFrom(
                minimumSize:
                    const Size(
                  double.infinity,
                  56,
                ),
              ),

              child: Text(

                _takipAktif
                    ? 'Takip Ediliyor...'
                    : 'Radarı Başlat',
              ),
            ),

            const SizedBox(height: 20),

            Text(

              'Son Veri:\n$_gelenMetin',

              style:
                  const TextStyle(
                fontSize: 12,
              ),

              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 30),

            const Align(

              alignment:
                  Alignment.centerLeft,

              child: Text(

                'Kayıtlı Yerler',

                style: TextStyle(

                  fontSize: 32,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_kayitliYerler.isEmpty)

              const Text(
                'Henüz kayıtlı yer yok.',
              )

            else

              ..._kayitliYerler.map((yer) {

                return Card(

                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: ListTile(

                    leading:
                        const Icon(
                      Icons.location_on,
                    ),

                    title: Text(

                      yer['name'] ??
                          'Paylaşılan Konum',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    onTap: () {

                      setState(() {

                        _hedefAdi =
                            yer['name'];

                        _gelenMetin =
                            '📂 Kayıt seçildi';
                      });
                    },

                    trailing:
                        IconButton(

                      icon:
                          const Icon(
                        Icons.delete,
                      ),

                      onPressed: () =>
                          _kaydiSil(
                        yer['id'],
                      ),
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