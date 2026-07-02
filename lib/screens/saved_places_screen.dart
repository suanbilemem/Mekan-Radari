import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../database_helper.dart';
import '../models/place_model.dart';
import '../services/map_launcher_service.dart';

// ─────────────────────────────────────────
// Yer adlarını tutarlı şekilde gösterir:
// "KARACAAHMET SULTAN" → "Karacaahmet Sultan"
// ─────────────────────────────────────────
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<PlaceModel> places = [];
  String selectedCategory = 'Hepsi';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlaces();
  }

  Future<void> loadPlaces() async {

    setState(() {
    isLoading = true;
  });
  
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
  isLoading = false;
    });
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

  void _showNoteDialog(
  BuildContext context,
  PlaceModel place,
) {

  final TextEditingController noteController =
      TextEditingController(
        text: place.note ?? '',
      );


  showDialog(
    context: context,

    builder: (dialogContext) {

      return Dialog(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  const Text(
                    'Not ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                  IconButton(

                    icon:
                    const Icon(Icons.close),

                    onPressed: () async {


                      final note =
                          noteController.text.trim();


                      await DatabaseHelper.instance
                          .updateNote(
                            place.id!,
                            note,
                          );


                      await loadPlaces();

                      if (!context.mounted) return;


                      Navigator.pop(dialogContext);
                      

                    },

                  ),

                ],

              ),


              const SizedBox(height: 10),


              TextField(

                controller: noteController,

                maxLength: 40,

                maxLines: 3,

                decoration:

                InputDecoration(

                  hintText:
                    'Not ekle',

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(8),

                  ),

                ),

              ),

            ],

          ),

        ),

      );

    },

  );

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
            Text(
              'Kayıtlı Yerler',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Kat.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Yer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Konum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Mesafe',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredPlaces.isEmpty
                    ? const Center(
                        child: Text('Kayıtlı yer bulunamadı'),
                      )
                    : ListView.separated(
                      itemCount: filteredPlaces.length,
                      separatorBuilder: (_,_) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = filteredPlaces[index];

                        return Slidable(
                          key: Key(place.id.toString()),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  _showNoteDialog(context, place);
                                },
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                icon: Icons.note,
                                label: 'Not',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  MapLauncherService.openPlace(place);
                                },
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                icon: Icons.location_on,
                                label: 'Konum',
                              ),
                              SlidableAction(
                                onPressed: (context) async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Kaydı Sil'),
                                      content: Text('${place.name} silinsin mi?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext, false);
                                          },
                                          child: const Text('Vazgeç'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            'Sil',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (result == true) {
                                    await DatabaseHelper.instance.deletePlace(place.id!);
                                    await loadPlaces();
                                  }
                                },
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Sil',
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {},
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
                                      toTitleCase(place.name),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      place.district,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
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