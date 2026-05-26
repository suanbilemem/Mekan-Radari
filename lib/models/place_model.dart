class PlaceModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String city;
  final String district;
  final bool saved;

  PlaceModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.city,
    required this.district,
    required this.saved,
  });
}