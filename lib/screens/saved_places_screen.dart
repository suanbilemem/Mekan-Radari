import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models/place_model.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({
    super.key,
  });

  @override
  State<SavedPlacesScreen> createState() =>
      _SavedPlacesScreenState();
}

class _SavedPlacesScreenState
    extends State<SavedPlacesScreen> {

  List<PlaceModel> places = [];

  String selectedCategory =
      'Hepsi';

  @override
  void initState() {
    super.initState();

    loadPlaces();
  }

  Future<void> loadPlaces() async {

    final data =
        await DatabaseHelper.instance
            .getPlaces();

    setState(() {

      places = data;
    });
  }

  Future<void> _deletePlace(
    PlaceModel place,
  ) async {

    final result =
        await showDialog<bool>(

      context: context,

      builder: (_) => AlertDialog(

        title: const Text(
          'Kaydı Sil',
        ),

        content: Text(
          '${place.name} silinsin mi?',
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(
                context,
                false,
              );
            },

            child: const Text(
              'Vazgeç',
            ),
          ),

          ElevatedButton(

            onPressed: () {

              Navigator.pop(
                context,
                true,
              );
            },

            child: const Text(
              'Sil',
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    await DatabaseHelper.instance
        .deletePlace(
      place.id!,
    );

    await loadPlaces();
  }

  IconData _getIcon(
    String category,
  ) {

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

  Color _getColor(
    String category,
  ) {

    switch (category) {

      case 'Yeme-İçme':
        return Colors.orange;

      case 'Sağlık':
        return Colors.red;

      case 'İbadet':
        return Colors.green;

      case 'Spor':
        return Colors.blue;

      case 'Park':
        return Colors.teal;

      case 'Alışveriş':
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {

    final filteredPlaces =

        selectedCategory == 'Hepsi'

            ? places

            : places.where((p) {

                return p.category ==
                    selectedCategory;

              }).toList();

    return SafeArea(

      child: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(

              'Kayıtlı Yerler',

              style: TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            DropdownButtonFormField<String>(

              value:
                  selectedCategory,

              decoration:
                  InputDecoration(

                filled: true,

                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  borderSide:
                      BorderSide.none,
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

                return DropdownMenuItem(

                  value: e,

                  child: Text(e),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  selectedCategory =
                      value!;
                });
              },
            ),

            const SizedBox(
              height: 18,
            ),

            Expanded(

              child:
                  filteredPlaces.isEmpty

                      ? const Center(

                          child: Text(
                            'Bu kategoride kayıt yok',
                          ),
                        )

                      : ListView.builder(

                          itemCount:
                              filteredPlaces.length,

                          itemBuilder:
                              (context, index) {

                            final place =
                                filteredPlaces[index];

                            final color =
                                _getColor(
                              place.category,
                            );

                            return Container(

                              margin:
                                  const EdgeInsets.only(
                                bottom: 14,
                              ),

                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),

                              decoration:
                                  BoxDecoration(

                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  22,
                                ),

                                boxShadow: [

                                  BoxShadow(

                                    color:
                                        Colors.black.withValues(
                                      alpha: 0.05,
                                    ),

                                    blurRadius: 10,
                                  ),
                                ],
                              ),

                              child: Row(

                                children: [

                                  Container(

                                    width: 54,
                                    height: 54,

                                    decoration:
                                        BoxDecoration(

                                      color:
                                          color.withValues(
                                        alpha: 0.15,
                                      ),

                                      shape:
                                          BoxShape.circle,
                                    ),

                                    child: Icon(

                                      _getIcon(
                                        place.category,
                                      ),

                                      color:
                                          color,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        Text(

                                          place.name,

                                          maxLines: 2,

                                          overflow:
                                              TextOverflow.ellipsis,

                                          style:
                                              const TextStyle(

                                            fontSize: 18,

                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 6,
                                        ),

                                        Text(

                                          place.category,

                                          style:
                                              TextStyle(

                                            color:
                                                color,

                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(

                                          '${place.district} / ${place.city}',

                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(

                                    onPressed: () {

                                      _deletePlace(
                                        place,
                                      );
                                    },

                                    icon: const Icon(
                                      Icons.delete,
                                    ),

                                    color: Colors.red,
                                  ),
                                ],
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