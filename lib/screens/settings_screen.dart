import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {

  double distance = 500;

  @override
  void initState() {
    super.initState();
    loadDistance();
  }

  Future<void> loadDistance() async {

    final prefs =
        await SharedPreferences.getInstance();

    setState(() {

      distance =
          prefs.getDouble(
            'trigger_distance',
          ) ??
          500;
    });
  }

  Future<void> saveDistance(
    double value,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setDouble(
      'trigger_distance',
      value,
    );
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Uyarı Mesafesi',
              style:
                  TextStyle(
                fontSize: 20,
              ),
            ),

            Slider(
              value: distance,
              min: 100,
              max: 2000,
              divisions: 19,
              label:
                  '${distance.toInt()} m',
              onChanged: (v) async {

                setState(() {
                  distance = v;
                });

                await saveDistance(v);
              },
            ),

            Center(
              child: Text(
                '${distance.toInt()} m',
                style:
                    const TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}