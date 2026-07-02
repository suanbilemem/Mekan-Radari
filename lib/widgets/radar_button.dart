import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/place_model.dart';
import '../services/location_service.dart';

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

enum _RadarState {
  idle,
  scanning,
  result,
}



class RadarButton extends StatefulWidget {

  const RadarButton({
    super.key,
  });


  @override
  State<RadarButton> createState() =>
      _RadarButtonState();

}



class _RadarButtonState extends State<RadarButton>
    with SingleTickerProviderStateMixin {


  _RadarState _state = _RadarState.idle;


  List<PlaceModel> _nearestPlaces = [];


  late AnimationController _waveController;


  final AudioPlayer _audioPlayer =
      AudioPlayer();
      Timer? _radarSoundTimer;



  static const Duration _minScanDuration =
      Duration(seconds:4);



  @override
  void initState(){

    super.initState();


    _waveController =
        AnimationController(
          vsync:this,
          duration:
          const Duration(seconds:3),
        );


  }




@override
void dispose(){

  _radarSoundTimer?.cancel();

  _waveController.dispose();

  _audioPlayer.dispose();

  super.dispose();

}


void _startRadarSound(){

  _radarSoundTimer?.cancel();


  _audioPlayer.play(
    AssetSource(
      'sounds/radar_ping.mp3',
    ),
  );


  _radarSoundTimer =
      Timer.periodic(
        const Duration(seconds:1),
        (timer){

          if(_state != _RadarState.scanning){

            timer.cancel();
            return;

          }


          _audioPlayer.play(
            AssetSource(
              'sounds/radar_ping.mp3',
            ),
          );


        },
      );

}

Future<void> _startScan() async {


  if(_state == _RadarState.scanning){
    return;
  }


setState((){

  _state =
      _RadarState.scanning;

  _nearestPlaces = [];

});



    _waveController.repeat();



_startRadarSound();




    final start =
        DateTime.now();



    final places =
        await LocationService.instance
            .getNearestFive();




    final elapsed =
        DateTime.now()
            .difference(start);



    final remaining =
        _minScanDuration -
            elapsed;



    if(remaining > Duration.zero){

      await Future.delayed(
        remaining,
      );

    }




    if(!mounted) return;



    _waveController.stop();



    setState((){

      _nearestPlaces =
          places;

      _state =
          _RadarState.result;

    });



  }







  @override
  Widget build(BuildContext context){


    return GestureDetector(

      onTap:_startScan,


      child:SizedBox(

        width:400,

        height:400,


        child:Stack(

          alignment:
          Alignment.center,


          children:[



            if(_state ==
                _RadarState.scanning)

              _buildWaves(),



            _buildCenterCircle(),



          ],

        ),

      ),

    );


  }









  Widget _buildWaves(){


    return AnimatedBuilder(

      animation:
      _waveController,


      builder:(context,child){


        return CustomPaint(

          size:
          const Size(
            400,
            400,
          ),


          painter:
          _RadarWavePainter(

            progress:
            _waveController.value,

          ),

        );


      },

    );


  }









  Widget _buildCenterCircle(){


    return Container(


      width:300,

      height:300,


      decoration:

      BoxDecoration(


        shape:
        BoxShape.circle,


        color:
        Colors.white,



        border:

        Border.all(

          color:
          Colors.green,

          width:10,

        ),



        boxShadow:[


          BoxShadow(

            color:
            Colors.green
                .withValues(alpha:0.25),


            blurRadius:40,


            spreadRadius:5,

          ),


        ],



      ),



      padding:
      const EdgeInsets.all(20),



      child:

      Center(

        child:
        _buildContent(),

      ),


    );


  }









  Widget _buildContent(){



    if(_state ==
        _RadarState.idle){


      return const Text(

        'Dokun\nve tara',


        textAlign:
        TextAlign.center,


        style:

        TextStyle(

          fontSize:18,

          fontWeight:
          FontWeight.bold,

        ),

      );

    }





    if(_state ==
        _RadarState.scanning){


      return const Text(

        'Taranıyor...',


        textAlign:
        TextAlign.center,


        style:

        TextStyle(

          color:
          Colors.green,

          fontSize:18,

          fontWeight:
          FontWeight.bold,

        ),

      );


    }






    return Column(

      mainAxisAlignment:
      MainAxisAlignment.center,


      children:

      _nearestPlaces.map((place){


        return Padding(

          padding:
          const EdgeInsets.symmetric(
              vertical:4
          ),


          child:

          Text(

            toTitleCase(place.name),


            maxLines:1,

            overflow:
            TextOverflow.ellipsis,


            style:

            const TextStyle(

              fontSize:15,

              fontWeight:
              FontWeight.w600,

            ),

          ),

        );


      }).toList(),


    );


  }



}









class _RadarWavePainter extends CustomPainter {
  final double progress;

  _RadarWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width *0.9;
    
    // Butonun bittiği yer (çapına göre burayı 95.0, 100.0 veya 120.0 yapabilirsin)
    final minRadius = 95.0; 

    // Kaç dalga yaptıysan o rakamı kullan (örneğin 3 veya 5)
    for (var i = 0; i < 5; i++) { 
      final phase = (progress + i / 5) % 1.0;
      final radius = minRadius + ((maxRadius - minRadius) * phase);

      // 1. BELİRGİNLİK (OPACITY) AYARI:
      // Ana daire %100 parlaktı. Dalga %80 (0.8) parlaklıktan başlıyor.
      // phase (ilerleme) arttıkça yavaşça 0.0'a (tam şeffaflığa) düşüyor.
      final opacity = (0.95 * (1.0 - phase)).clamp(0.0, 1.0);

      // 2. KALINLIK (STROKE WIDTH) AYARI:
      // Ana dairenin kalınlığı 2.0'dı. Dalga 1.5'ten başlıyor.
      // Dışa yayıldıkça yavaşça incelerek kayboluyor.
        final currentThickness = 12.5 * (1.0 - (phase * 0.5));

      final paint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentThickness; // Sabit rakam yerine hesaplanan kalınlığı verdik

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}