import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}


  class _SettingsScreenState
      extends State<SettingsScreen> {

    double? distance;
    bool? sound;
    bool? vibration;

    final _settingsService = SettingsService.instance;

    @override
    void initState() {
      super.initState();

      loadSettings();
    }

    Future<void> loadSettings() async {
      final d = await _settingsService.getDistance();
      final s = await _settingsService.getSound();
      final v = await _settingsService.getVibration();

      setState(() {
        distance = d;
        sound = s;
        vibration = v;
      });
    }




    Widget sectionTitle(
      String text,
      IconData icon,
    ){

      return Padding(
        padding:
            const EdgeInsets.only(
              top:20,
              bottom:10,
            ),

        child: Row(

          children:[

            Icon(
              icon,
              color:Colors.red,
            ),

            const SizedBox(
              width:10,
            ),

            Text(
              text,
              style:
                const TextStyle(
                  fontSize:20,
                  fontWeight:
                    FontWeight.bold,
                ),
            ),

          ],

        ),

      );

    }



  Widget settingCard(
    Widget child,
  ){

    return Card(

      elevation:2,

      shape:
        RoundedRectangleBorder(
          borderRadius:
            BorderRadius.circular(18),
        ),

      child:
        Padding(

          padding:
            const EdgeInsets.all(16),

          child:child,

        ),

    );

  }



  Widget switchRow(
    String title,
    bool value,
    Function(bool) onChanged,
  ){

    return Row(

      mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

      children:[

        Text(
          title,
          style:
            const TextStyle(
              fontSize:17,
            ),
        ),


        Switch(

          value:value,

          activeThumbColor: Colors.red,

          onChanged:onChanged,

        ),

      ],

    );

  }




@override
Widget build(BuildContext context) {

  if (distance == null ||
      sound == null ||
      vibration == null) {

    return const Center(
      child: CircularProgressIndicator(),
    );
  }


    return SafeArea(

      child:

      ListView(

        padding:
          const EdgeInsets.all(20),


        children:[


          const Text(
            'Ayarlar',

            style:
              TextStyle(
                fontSize:32,
                fontWeight:
                  FontWeight.bold,
              ),
          ),



          // GÖRÜNÜM

          sectionTitle(
            'Görünüm',
            Icons.dark_mode,
          ),


         settingCard(

  Consumer<ThemeProvider>(

    builder: (context, theme, child){

      return switchRow(

        'Koyu Tema',

        theme.darkMode,

        (value){

          theme.toggleTheme(value);

        },

      );

    },

  ),

),


          // RADAR

          sectionTitle(
            'Radar',
            Icons.radar,
          ),


          settingCard(

            Column(

              crossAxisAlignment:
                CrossAxisAlignment.start,


              children:[


                const Text(
                  'Yaklaşma mesafesi',
                  style:
                    TextStyle(
                      fontSize:17,
                    ),
                ),


                Slider(

                  value:
                    distance ?? 100.0,

                  min:
                    100,

                  max:
                    1000,

                  divisions:
                    9,

                  label:
                    '${(distance ?? 100.0).toInt()} m',


                  activeColor:
                    Colors.red,


                  onChanged:
                    (v) async{

                      setState((){
                        distance=v;
                      });
                      await _settingsService.setDistance(v);
                    },

                ),



                Center(

                  child:

                  Text(

                    '${(distance ?? 100.0).toInt()} m',

                    style:
                      const TextStyle(

                        fontSize:28,

                        fontWeight:
                          FontWeight.bold,

                      ),

                  ),

                ),


              ],

            ),

          ),





          // BİLDİRİM

          sectionTitle(
            'Bildirim',
            Icons.notifications,
          ),


          settingCard(

            Column(

              children:[


                switchRow(

                  'Ses',

                  sound ?? true,
                  (v){
                    setState((){
                      sound=v;
                    });
                    _settingsService.setSound(v);
                  },

                ),



                switchRow(

                  'Titreşim',

                  vibration ?? true,
                  (v){
                    setState((){
                      vibration=v;
                    });
                    _settingsService.setVibration(v);
                  },

                ),


              ],

            ),

          ),

        ],

      ),

    );

  }

}