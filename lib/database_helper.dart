import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/place_model.dart';


class DatabaseHelper {

  static final DatabaseHelper instance =
      DatabaseHelper._init();


  static Database? _database;


  DatabaseHelper._init();



  Future<Database> get database async {

    if (_database != null) {
      return _database!;
    }


    _database =
        await _initDB('places.db');


    return _database!;

  }





  Future<Database> _initDB(
    String filePath,
  ) async {


    final dbPath =
        await getDatabasesPath();


    final path =
        join(
          dbPath,
          filePath,
        );



    return await openDatabase(

      path,


      version: 2,


      onCreate: _createDB,


      onUpgrade: _upgradeDB,

    );

  }






  // İLK KURULUM
  Future<void> _createDB(
    Database db,
    int version,
  ) async {


    await db.execute('''

CREATE TABLE places(

  id INTEGER PRIMARY KEY AUTOINCREMENT,

  name TEXT,

  city TEXT,

  district TEXT,

  category TEXT,

  lat REAL,

  lng REAL,

  note TEXT

)

''');


  }
  // ESKİ VERİTABANINI GÜNCELLE
  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {


    if(oldVersion < 2){


      await db.execute(
        '''
        ALTER TABLE places
        ADD COLUMN note TEXT
        '''
      );


    }


  }
  // YER EKLE
  Future<void> insertPlace(
    PlaceModel place,
  ) async {


    final db =
        await database;



    final existing =
        await db.query(

      'places',

      where:
          'name = ? AND city = ?',


      whereArgs:[
        place.name,
        place.city,
      ],

    );



    if(existing.isNotEmpty){

      return;

    }




    await db.insert(

      'places',

      place.toMap(),

    );


  }

  // TÜM YERLER
  Future<List<PlaceModel>>
      getPlaces() async {


    final db =
        await database;



    final result =
        await db.query(

      'places',

      orderBy:
          'id DESC',

    );



    return result.map(

      (e) => PlaceModel.fromMap(e),

    ).toList();


  }









  // NOT GÜNCELLE
  Future<void> updatePlaceNote(
    int id,
    String note,
  ) async {


    final db =
        await database;



    await db.update(

      'places',


      {

        'note': note,

      },


      where:

        'id = ?',


      whereArgs:[

        id,

      ],


    );


  }









  // TEK YER SİL
  Future<void> deletePlace(
    int id,
  ) async {


    final db =
        await database;



    await db.delete(

      'places',


      where:

        'id = ?', 


      whereArgs:[

        id,

      ],


    );


  }

// NOT GÜNCELLE
Future<void> updateNote(
  int id,
  String note,
) async {

  final db = await database;

  await db.update(
    'places',
    {
      'note': note,
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

  // TÜMÜNÜ SİL
  Future<void> deleteAllPlaces()
  async {


    final db =
        await database;



    await db.delete(

      'places',

    );


  }









  // KAYIT SAYISI
  Future<int> getPlaceCount()
  async {


    final db =
        await database;



    final result =
        await db.rawQuery(

      'SELECT COUNT(*) FROM places',

    );



    return Sqflite.firstIntValue(

          result,

        ) ?? 0;


  }








  Future<void> close() async {


    final db =
        await database;


    db.close();


  }


}