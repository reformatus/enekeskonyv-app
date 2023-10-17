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
          PopupMenuButton(
              itemBuilder: (i) => [
                    // Import button
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.content_paste),
                        title: Text('Importálás'),
                      ),
                      onTap: () {
                        // TODO implement
                      },
                    ),
                    // Export button
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Exportálás'),
                      ),
                      onTap: () {
                        // TODO implement
                      },
                    ),
                    // Delete all button
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Összes törlése'),
                      ),
                      onTap: () {
                        // TODO implement
                      },
                    ),
                  ])
        ],
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}
