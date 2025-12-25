import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Settings")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Here you can manage data sharing, permissions, and account security options.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}