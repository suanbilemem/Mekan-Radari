import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  double distance = 500;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Uyarı Mesafesi',
              style: TextStyle(fontSize: 20),
            ),

            Slider(
              value: distance,
              min: 100,
              max: 2000,
              divisions: 19,
              label: '${distance.toInt()} m',
              onChanged: (v) {
                setState(() {
                  distance = v;
                });
              },
            ),

            Center(
              child: Text(
                '${distance.toInt()} m',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}