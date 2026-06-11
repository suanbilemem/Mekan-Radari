import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../database_helper.dart';
import '../models/place_model.dart';
import '../services/map_launcher_service.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<PlaceModel> places = [];

  String selectedCategory = 'Hepsi';

  @override
  void initState() {
    super.initState();
    loadPlaces();
  }

  Future<void> loadPlaces() async {
    final data = await DatabaseHelper.instance.getPlaces();

    try {
      final currentPosition = await Geolocator.getCurrentPosition();

      for (final place in data) {
        place.distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          place.lat,
          place.lng,
        );
      }

      data.sort((a, b) => a.distance.compareTo(b.distance));
    } catch (e) {
      debugPrint('Mesafe hesaplanamadı: $e');
    }

    setState(() {
      places = data;
    });
  }

  Future<void> _deletePlace(PlaceModel place) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: Text('${place.name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result != true) return;

    await DatabaseHelper.instance.deletePlace(place.id!);

    await loadPlaces();
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Yeme-İçme':
        return Icons.restaurant;

      case 'Sağlık':
        return Icons.local_hospital;

      case 'İbadet':
        return Icons.mosque;

      case 'Spor':
        return Icons.sports_soccer;

      case 'Park':
        return Icons.park;

      case 'Alışveriş':
        return Icons.shopping_bag;

      default:
        return Icons.place;
    }
  }

  String _distanceText(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = selectedCategory == 'Hepsi'
        ? places
        : places.where((p) {
            return p.category == selectedCategory;
          }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kayıtlı Yerler',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items:
                  [
                    'Hepsi',
                    'Yeme-İçme',
                    'Sağlık',
                    'İbadet',
                    'Spor',
                    'Park',
                    'Alışveriş',
                    'Diğer',
                  ].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Kat.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Yer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Konum',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Mesafe',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: filteredPlaces.isEmpty
                  ? const Center(child: Text('Kayıtlı yer bulunamadı'))
                  : ListView.separated(
                      itemCount: filteredPlaces.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = filteredPlaces[index];

                        return Dismissible(
                          key: Key(place.id.toString()),

                          direction: DismissDirection.endToStart,

                          confirmDismiss: (_) async {
                            final result = await showDialog<bool>(
                              context: context,

                              builder: (_) => AlertDialog(
                                title: const Text('Kaydı Sil'),

                                content: Text('${place.name} silinsin mi?'),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },

                                    child: const Text('Vazgeç'),
                                  ),

                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },

                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );

                            return result ?? false;
                          },

                          onDismissed: (_) async {
                            await DatabaseHelper.instance.deletePlace(
                              place.id!,
                            );

                            await loadPlaces();
                          },

                          background: Container(
                            color: Colors.red,

                            alignment: Alignment.centerRight,

                            padding: const EdgeInsets.only(right: 24),

                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),

                          child: InkWell(
                            onTap: () {
                              MapLauncherService.openPlace(place);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),

                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Icon(
                                      _getIcon(place.category),
                                      size: 22,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      place.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${place.district}/${place.city}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      _distanceText(place.distance),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
