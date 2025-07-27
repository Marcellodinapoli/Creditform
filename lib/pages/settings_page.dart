import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Tema scuro'),
            subtitle: Text('Coming soon 🔜'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifiche'),
            subtitle: Text('Coming soon 🔜'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // TODO: aggiungi logica di logout quando implementerai FirebaseAuth
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout non ancora implementato')),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Info su CreditForm'),
            subtitle: Text('Versione 1.0.0'),
          ),
        ],
      ),
    );
  }
}
