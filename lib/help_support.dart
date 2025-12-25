import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(
            leading: Icon(Icons.email),
            title: Text("Contact Support"),
            subtitle: Text("support@smartcar.com"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("About this App"),
            subtitle: Text("Version 1.0.0 • Developed by Anas"),
          ),
        ],
      ),
    );
  }
}