class PlaceModel {

  final int? id;

  final String name;
  final String city;
  final String district;

  final String category;

  final double lat;
  final double lng;

  // Kullanıcının isteğe bağlı yazdığı not
  String? note;

  // Ekranda mesafe göstermek için kullanılır
  double distance = 0;


  PlaceModel({
    this.id,

    required this.name,

    required this.city,

    required this.district,

    required this.category,

    required this.lat,

    required this.lng,

    this.note,

    this.distance = 999999,
  });



  Map<String, dynamic> toMap() {

    return {

      'id': id,

      'name': name,

      'city': city,

      'district': district,

      'category': category,

      'lat': lat,

      'lng': lng,

      'note': note,

    };

  }



  factory PlaceModel.fromMap(
    Map<String, dynamic> map,
  ) {

    return PlaceModel(

      id: map['id'],

      name: map['name'],

      city: map['city'],

      district: map['district'],

      category: map['category'],

      lat: map['lat'],

      lng: map['lng'],

      note: map['note'],

    );

  }

}