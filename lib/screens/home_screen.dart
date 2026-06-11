import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../database_helper.dart';
import '../models/place_model.dart';
import '../widgets/radar_circle.dart';

import 'saved_places_screen.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _intentSubscription;

  bool _loading = false;
  bool _saved = false;

  String placeName = 'Google Haritalar’dan Yer Paylaşın';

  String city = '';
  String district = '';

  String category = 'Diğer';

  IconData categoryIcon = Icons.place;

  double lat = 0;
  double lng = 0;

  int _currentIndex = 0;
  int _savedPlacesRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _listenSharing();
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenSharing() async {
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        if (value.isNotEmpty) {
          final text = value.first.path.toString();

          _resolvePlace(text);
        }
      },
    );

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();

    if (initial.isNotEmpty) {
      _resolvePlace(initial.first.path.toString());
    }
  }

  Future<void> _resolvePlace(String text) async {
    setState(() {
      _loading = true;
      _saved = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://mekan-radari.onrender.com/resolve'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({'text': text}),
      );

      final data = jsonDecode(response.body);

      debugPrint('DISTRICT: ${data['district']}');

      debugPrint('CITY: ${data['city']}');

      final List types = data['types'] ?? [];

      _setCategory(types, data['name'] ?? '');

      final place = PlaceModel(
        name: data['name'] ?? 'Yer',
        city: data['city'] ?? '',
        district: data['district'] ?? '',
        category: category,
        lat: (data['lat'] ?? 0).toDouble(),
        lng: (data['lng'] ?? 0).toDouble(),
      );

      await DatabaseHelper.instance.insertPlace(place);

      await NotificationService.instance.showSavedNotification(place);

      ReceiveSharingIntent.instance.reset();

      _showSavedPlacesAfterShareSave();

      return;
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  void _showSavedPlacesAfterShareSave() {
    if (!mounted) return;

    setState(() {
      _currentIndex = 1;
      _savedPlacesRefreshKey++;
      _loading = false;
      _saved = true;
    });
  }

  void _setCategory(List types, String name) {
    final lowerName = name.toLowerCase();

    // YEME İÇME
    if (types.contains('restaurant') ||
        types.contains('food') ||
        types.contains('cafe') ||
        lowerName.contains('restaurant') ||
        lowerName.contains('cafe') ||
        lowerName.contains('kahve') ||
        lowerName.contains('coffee') ||
        lowerName.contains('burger') ||
        lowerName.contains('pizza') ||
        lowerName.contains('kebap') ||
        lowerName.contains('lokanta') ||
        lowerName.contains('pastane')) {
      category = 'Yeme-İçme';
      categoryIcon = Icons.restaurant;
    }
    // SAĞLIK
    else if (types.contains('hospital') ||
        types.contains('health') ||
        types.contains('doctor') ||
        types.contains('dentist') ||
        types.contains('drugstore') ||
        types.contains('pharmacy') ||
        lowerName.contains('hastane') ||
        lowerName.contains('eczane') ||
        lowerName.contains('klinik') ||
        lowerName.contains('sağlık') ||
        lowerName.contains('acil')) {
      category = 'Sağlık';
      categoryIcon = Icons.local_hospital;
    }
    // EĞİTİM
    else if (types.contains('school') ||
        types.contains('university') ||
        lowerName.contains('okul') ||
        lowerName.contains('üniversite') ||
        lowerName.contains('kolej') ||
        lowerName.contains('akademi') ||
        lowerName.contains('lise')) {
      category = 'Eğitim';
      categoryIcon = Icons.school;
    }
    // İBADET
    else if (types.contains('mosque') ||
        types.contains('place_of_worship') ||
        lowerName.contains('cami') ||
        lowerName.contains('camii') ||
        lowerName.contains('mescit') ||
        lowerName.contains('kilise') ||
        lowerName.contains('sinagog')) {
      category = 'İbadet';
      categoryIcon = Icons.mosque;
    }
    // SPOR
    else if (types.contains('stadium') ||
        types.contains('gym') ||
        lowerName.contains('spor') ||
        lowerName.contains('voleybol') ||
        lowerName.contains('basketbol') ||
        lowerName.contains('futbol') ||
        lowerName.contains('arena') ||
        lowerName.contains('fitness') ||
        lowerName.contains('stadyum') ||
        lowerName.contains('stad')) {
      category = 'Spor';
      categoryIcon = Icons.sports_soccer;
    }
    // ALIŞVERİŞ
    else if (types.contains('shopping_mall') ||
        types.contains('store') ||
        lowerName.contains('avm') ||
        lowerName.contains('migros') ||
        lowerName.contains('a101') ||
        lowerName.contains('bim') ||
        lowerName.contains('şok') ||
        lowerName.contains('carrefour')) {
      category = 'Alışveriş';
      categoryIcon = Icons.shopping_bag;
    }
    // PARK
    else if (types.contains('park') ||
        lowerName.contains('park') ||
        lowerName.contains('koru') ||
        lowerName.contains('mesire')) {
      category = 'Park';
      categoryIcon = Icons.park;
    }
    // KÜLTÜR SANAT
    else if (types.contains('museum') ||
        types.contains('art_gallery') ||
        lowerName.contains('müze') ||
        lowerName.contains('galeri') ||
        lowerName.contains('sanat') ||
        lowerName.contains('tiyatro') ||
        lowerName.contains('opera')) {
      category = 'Kültür';
      categoryIcon = Icons.museum;
    }
    // KONAKLAMA
    else if (types.contains('lodging') ||
        types.contains('hotel') ||
        lowerName.contains('otel') ||
        lowerName.contains('hotel') ||
        lowerName.contains('hostel')) {
      category = 'Konaklama';
      categoryIcon = Icons.hotel;
    }
    // ULAŞIM
    else if (types.contains('airport') ||
        types.contains('bus_station') ||
        types.contains('train_station') ||
        types.contains('subway_station') ||
        lowerName.contains('metro') ||
        lowerName.contains('istasyon') ||
        lowerName.contains('otogar') ||
        lowerName.contains('iskele') ||
        lowerName.contains('havaalanı')) {
      category = 'Ulaşım';
      categoryIcon = Icons.directions_bus;
    }
    // İŞ MERKEZİ
    else if (lowerName.contains('plaza') ||
        lowerName.contains('iş merkezi') ||
        lowerName.contains('business') ||
        lowerName.contains('tower')) {
      category = 'İş Merkezi';
      categoryIcon = Icons.business;
    }
    // RESMİ KURUM
    else if (lowerName.contains('belediye') ||
        lowerName.contains('kaymakamlık') ||
        lowerName.contains('mahkeme') ||
        lowerName.contains('nüfus')) {
      category = 'Resmi Kurum';
      categoryIcon = Icons.account_balance;
    } else {
      category = 'Diğer';
      categoryIcon = Icons.place;
    }
  }

  Future<void> _savePlace() async {
    if (placeName == 'Google Haritalar’dan Yer Paylaşın') {
      return;
    }

    final place = PlaceModel(
      name: placeName,

      city: city,

      district: district,

      category: category,

      lat: lat,

      lng: lng,
    );

    await DatabaseHelper.instance.insertPlace(place);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$placeName kaydedildi'),

        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHome(),

      SavedPlacesScreen(key: ValueKey(_savedPlacesRefreshKey)),

      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (i) {
          setState(() {
            _currentIndex = i;
          });
        },

        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Ana Ekran'),

          NavigationDestination(icon: Icon(Icons.list), label: 'Kayıtlı'),

          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : RadarCircle(
                saved: _saved,

                onTap: _savePlace,

                placeName: placeName,

                city: city,

                district: district,

                category: category,

                categoryIcon: categoryIcon,
              ),
      ),
    );
  }
}
