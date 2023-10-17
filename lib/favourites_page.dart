import 'package:flutter/material.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kedvencek'),
        actions: [
          // Import button
          IconButton(
              tooltip: 'Importálás',
              onPressed: () {
                // TODO implement
              },
              icon: const Icon(Icons.download)),
          // Export button
          IconButton(
              tooltip: 'Exportálás',
              onPressed: () {
                // TODO implement
              },
              icon: const Icon(Icons.upload)),
          // Delete all button
          IconButton(
              tooltip: 'Összes törlése',
              onPressed: () {
                // TODO implement
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}
