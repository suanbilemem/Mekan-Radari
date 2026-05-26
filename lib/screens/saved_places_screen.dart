import 'package:flutter/material.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kayıtlı Yerler',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrele...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                DropdownButton<int>(
                  value: 10,
                  items: const [
                    DropdownMenuItem(
                      value: 5,
                      child: Text('5'),
                    ),
                    DropdownMenuItem(
                      value: 10,
                      child: Text('10'),
                    ),
                    DropdownMenuItem(
                      value: 25,
                      child: Text('25'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Hepsi')),
                Chip(label: Text('🍽️ Yeme-İçme')),
                Chip(label: Text('🛍️ Alışveriş')),
                Chip(label: Text('🌲 Park')),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Text('🍽️'),
                      title: Text('Restoran ${index + 1}'),
                      subtitle: const Text('Yeme-İçme'),
                      trailing: const Text('1.2 km'),
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