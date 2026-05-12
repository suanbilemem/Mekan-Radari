import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sqflite/sqflite.dart';

void main() {
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

class KayitliYer {
  final int? id;
  final String ad;
  final double lat;
  final double lng;
  final DateTime tarih;

  KayitliYer({
    this.id,
    required this.ad,
    required this.lat,
    required this.lng,
    required this.tarih,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'lat': lat,
      'lng': lng,
      'tarih': tarih.toIso8601String(),
    };
  }

  factory KayitliYer.fromMap(Map<String, dynamic> map) {
    return KayitliYer(
      id: map['id'] as int?,
      ad: map['ad'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      tarih: DateTime.parse(map['tarih'] as String),
    );
  }
}

class VeritabaniServisi {
  static final VeritabaniServisi instance = VeritabaniServisi._();
  VeritabaniServisi._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yer_radari.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE yerler(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ad TEXT NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            tarih TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  Future<int> yerKaydet(KayitliYer yer) async {
    final database = await db;
    return database.insert('yerler', yer.toMap());
  }

  Future<List<KayitliYer>> tumYerleriGetir() async {
    final database = await db;
    final maps = await database.query(
      'yerler',
      orderBy: 'id DESC',
    );

    return maps.map((e) => KayitliYer.fromMap(e)).toList();
  }

  Future<void> yerSil(int id) async {
    final database = await db;
    await database.delete(
      'yerler',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class RadarHome extends StatefulWidget {
  const RadarHome({super.key});

  @override
  State<RadarHome> createState() => _RadarHomeState();
}

class _RadarHomeState extends State<RadarHome> {
  late StreamSubscription _intentDataStreamSubscription;
  StreamSubscription<geo.Position>? _positionStream;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  String _gelenMetin = 'Bekleniyor...';
  double? _hedefEnlem;
  double? _hedefBoylam;

  double _secilenMesafe = 500;
  bool _takipAktif = false;
  bool _yukleniyor = false;

  List<KayitliYer> _kayitliYerler = [];

  @override
  void initState() {
    super.initState();
    _sistemleriKur();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _sistemleriKur() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: android),
    );

    await geo.Geolocator.requestPermission();

    await _kayitliYerleriYukle();

    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        if (value.isNotEmpty) {
          final text = value.first.path;
          debugPrint('📥 PAYLAŞIM GELDİ: $text');
          _linkiCozVeIsle(text);
        }
      },
      onError: (err) {
        debugPrint('Paylaşım hatası: $err');
      },
    );

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initial.isNotEmpty) {
      _linkiCozVeIsle(initial.first.path);
    }

    ReceiveSharingIntent.instance.reset();
  }

  Future<void> _kayitliYerleriYukle() async {
    final yerler = await VeritabaniServisi.instance.tumYerleriGetir();

    if (!mounted) return;

    setState(() {
      _kayitliYerler = yerler;
    });
  }

  Future<void> _linkiCozVeIsle(String metin) async {
    setState(() {
      _gelenMetin = metin;
      _yukleniyor = true;
      _hedefEnlem = null;
      _hedefBoylam = null;
    });

    try {
      final String sunucuIp = '192.168.0.19'; // Kendi bilgisayar IP adresin
      final url = Uri.parse('http://$sunucuIp:3000/resolve');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': metin}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['lat'] != null) {
        final double lat = (data['lat'] as num).toDouble();
        final double lng = (data['lng'] as num).toDouble();

        setState(() {
          _hedefEnlem = lat;
          _hedefBoylam = lng;
          _yukleniyor = false;
          _gelenMetin = '✅ Konum çözüldü';
        });

        final yer = KayitliYer(
          ad: 'Paylaşılan Konum',
          lat: lat,
          lng: lng,
          tarih: DateTime.now(),
        );

        await VeritabaniServisi.instance.yerKaydet(yer);
        await _kayitliYerleriYukle();
      } else {
        setState(() {
          _yukleniyor = false;
          _gelenMetin = '❌ ${data['error'] ?? 'Sunucu hatası'}';
        });
      }
    } on TimeoutException {
      setState(() {
        _yukleniyor = false;
        _gelenMetin = '⏱️ Sunucuya ulaşılamadı (timeout)';
      });
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _gelenMetin = 'Bağlantı hatası 😕\n$e';
      });
    }
  }

  void _radariBaslat() {
    if (_hedefEnlem == null || _hedefBoylam == null) return;

    setState(() {
      _takipAktif = true;
    });

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

      debugPrint('📍 Mesafe: $mesafe');

      if (mesafe <= _secilenMesafe) {
        await _notifications.show(
          100,
          '🎯 HEDEFE GELDİN!',
          'Belirlediğin mesafeye ulaştın',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'radar',
              'Radar',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        await _positionStream?.cancel();

        if (!mounted) return;

        setState(() {
          _takipAktif = false;
        });
      }
    });
  }

  Future<void> _yerSil(int id) async {
    await VeritabaniServisi.instance.yerSil(id);
    await _kayitliYerleriYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yer Radarı'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _yukleniyor
                      ? const Center(child: CircularProgressIndicator())
                      : Icon(
                          Icons.radar,
                          size: 80,
                          color: _hedefEnlem != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                  const SizedBox(height: 20),
                  Text(
                    _hedefEnlem != null
                        ? '✅ Konum Alındı'
                        : "Google Haritalar'dan Yer Paylaşın",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_hedefEnlem != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '📍 $_hedefEnlem, $_hedefBoylam',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 30),
                  Text(
                    'Uyarı Mesafesi: ${_secilenMesafe.toInt()} m',
                    textAlign: TextAlign.center,
                  ),
                  Slider(
                    value: _secilenMesafe,
                    min: 100,
                    max: 2000,
                    onChanged: (v) {
                      setState(() {
                        _secilenMesafe = v;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        (_hedefEnlem == null || _takipAktif)
                            ? null
                            : _radariBaslat,
                    child: Text(
                      _takipAktif
                          ? 'Takip Ediliyor...'
                          : 'Radarı Başlat',
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Son Veri:\n$_gelenMetin',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Kayıtlı Yerler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_kayitliYerler.isEmpty)
                    const Text('Henüz kayıtlı yer yok.')
                  else
                    ..._kayitliYerler.map(
                      (yer) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.place),
                          title: Text(yer.ad),
                          subtitle: Text(
                            '${yer.lat.toStringAsFixed(6)}, '
                            '${yer.lng.toStringAsFixed(6)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: yer.id == null
                                ? null
                                : () => _yerSil(yer.id!),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}