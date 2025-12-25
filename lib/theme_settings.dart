import 'package:flutter/material.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Theme Settings")),
      body: Column(
        children: [
          RadioListTile(
            value: 'Light',
            groupValue: _selectedTheme,
            title: const Text("Light Theme"),
            onChanged: (val) => setState(() => _selectedTheme = val!),
          ),
          RadioListTile(
            value: 'Dark',
            groupValue: _selectedTheme,
            title: const Text("Dark Theme"),
            onChanged: (val) => setState(() => _selectedTheme = val!),
          ),
          RadioListTile(
            value: 'System',
            groupValue: _selectedTheme,
            title: const Text("System Default"),
            onChanged: (val) => setState(() => _selectedTheme = val!),
          ),
        ],
      ),
    );
  }
}