import 'package:flutter/material.dart';

class RadarCircle extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  final String placeName;
  final String city;
  final String district;
  final String category;

  final IconData categoryIcon;

  const RadarCircle({
    super.key,
    required this.saved,
    required this.onTap,
    required this.placeName,
    required this.city,
    required this.district,
    required this.category,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        saved ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 500,
        ),
        width: 310,
        height: 310,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: borderColor,
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(
                alpha: 0.35,
              ),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        placeName,
                        textAlign:
                            TextAlign.center,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        district.isNotEmpty &&
                                city.isNotEmpty
                            ? '$district / $city'
                            : city,
                        textAlign:
                            TextAlign.center,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          color:
                              Colors.black54,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      borderColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcon,
                      color: borderColor,
                      size: 24,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}