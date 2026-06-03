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

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  StreamSubscription?
      _intentSubscription;

  bool _loading = false;
  bool _saved = false;

  String placeName =
      'Google Haritalar’dan Yer Paylaşın';

  String city = '';
  String district = '';

  String category = 'Diğer';

  IconData categoryIcon =
      Icons.place;

  double lat = 0;
  double lng = 0;

  int _currentIndex = 0;

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

  Future<void>
      _listenSharing() async {

    _intentSubscription =
        ReceiveSharingIntent
            .instance
            .getMediaStream()
            .listen((value) {

      if (value.isNotEmpty) {

        final text =
            value.first.path
                .toString();

        _resolvePlace(text);
      }
    });

    final initial =
        await ReceiveSharingIntent
            .instance
            .getInitialMedia();

    if (initial.isNotEmpty) {

      _resolvePlace(
        initial.first.path
            .toString(),
      );
    }
  }

  Future<void> _resolvePlace(
    String text,
  ) async {

    setState(() {

      _loading = true;
      _saved = false;
    });

    try {

      final response =
          await http.post(

        Uri.parse(
          'https://mekan-radari.onrender.com/resolve',
        ),

        headers: {

          'Content-Type':
              'application/json',
        },

        body: jsonEncode({

          'text': text,
        }),
      );

      final data =jsonDecode(response.body,
          );

          debugPrint(
  'DISTRICT: ${data['district']}',
);

debugPrint(
  'CITY: ${data['city']}',
);

      final List types =
          data['types'] ?? [];

      _setCategory(types);

setState(() {

  placeName =
      data['name'] ?? 'Yer';

  String rawDistrict =
      data['district'] ?? '';

  String rawCity =
      data['city'] ?? '';

  // 34672 Üsküdar/İstanbul
  if (rawDistrict.contains('/')) {

    final parts =
        rawDistrict.split('/');

    district =
        parts[0]
            .replaceAll(
              RegExp(r'\d+'),
              '',
            )
            .trim();

    city =
        parts.length > 1
            ? parts[1].trim()
            : rawCity;
  } else {

    district = rawDistrict;
    city = rawCity;
  }

  lat =
      (data['lat'] ?? 0).toDouble();

  lng =
      (data['lng'] ?? 0).toDouble();

  _loading = false;
});

    } catch (e) {

      debugPrint(
        e.toString(),
      );

      setState(() {

        _loading = false;
      });
    }
  }

  void _setCategory(
    List types,
  ) {

    if (
      types.contains(
        'restaurant',
      ) ||
      types.contains(
        'food',
      ) ||
      types.contains(
        'cafe',
      )
    ) {

      category =
          'Yeme-İçme';

      categoryIcon =
          Icons.restaurant;
    }

    else if (
      types.contains(
        'hospital',
      )
    ) {

      category =
          'Sağlık';

      categoryIcon =
          Icons.local_hospital;
    }

    else if (
      types.contains(
        'mosque',
      ) ||
      types.contains(
        'place_of_worship',
      )
    ) {

      category =
          'İbadet';

      categoryIcon =
          Icons.mosque;
    }

    else if (
      types.contains(
        'stadium',
      ) ||
      types.contains(
        'gym',
      )
    ) {

      category =
          'Spor';

      categoryIcon =
          Icons.sports_soccer;
    }

    else if (
      types.contains(
        'shopping_mall',
      ) ||
      types.contains(
        'store',
      )
    ) {

      category =
          'Alışveriş';

      categoryIcon =
          Icons.shopping_bag;
    }

    else if (
      types.contains(
        'park',
      )
    ) {

      category =
          'Park';

      categoryIcon =
          Icons.park;
    }

    else {

      category =
          'Diğer';

      categoryIcon =
          Icons.place;
    }
  }

  Future<void>
      _savePlace() async {

    if (placeName ==
        'Google Haritalar’dan Yer Paylaşın') {
      return;
    }

    final place =
        PlaceModel(

      name: placeName,

      city: city,

      district: district,

      category: category,

      lat: lat,

      lng: lng,
    );

    await DatabaseHelper
        .instance
        .insertPlace(place);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(
          '$placeName kaydedildi',
        ),

        duration:
            const Duration(
          seconds: 2,
        ),
      ),
    );

    setState(() {

      _saved = true;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    final screens = [

      _buildHome(),

      const SavedPlacesScreen(),

      const SettingsScreen(),
    ];

    return Scaffold(

      body:
          screens[
              _currentIndex],

      bottomNavigationBar:
          NavigationBar(

        selectedIndex:
            _currentIndex,

        onDestinationSelected:
            (i) {

          setState(() {

            _currentIndex =
                i;
          });
        },

        destinations: const [

          NavigationDestination(

            icon: Icon(
              Icons.home,
            ),

            label:
                'Ana Ekran',
          ),

          NavigationDestination(

            icon: Icon(
              Icons.list,
            ),

            label:
                'Kayıtlı',
          ),

          NavigationDestination(

            icon: Icon(
              Icons.settings,
            ),

            label:
                'Ayarlar',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {

    return SafeArea(

      child: Center(

        child:
            _loading

                ? const CircularProgressIndicator()

                : RadarCircle(

                    saved:
                        _saved,

                    onTap:
                        _savePlace,

                    placeName:
                        placeName,

                    city:
                        city,

                    district:
                        district,

                    category:
                        category,

                    categoryIcon:
                        categoryIcon,
                  ),
      ),
    );
  }
}