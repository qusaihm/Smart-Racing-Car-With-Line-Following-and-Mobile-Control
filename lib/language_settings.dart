import 'package:flutter/material.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language Settings")),
      body: ListView(
        children: [
          RadioListTile(
            value: 'English',
            groupValue: _selectedLanguage,
            title: const Text("English"),
            onChanged: (val) => setState(() => _selectedLanguage = val!),
          ),
          RadioListTile(
            value: 'Arabic',
            groupValue: _selectedLanguage,
            title: const Text("Arabic"),
            onChanged: (val) => setState(() => _selectedLanguage = val!),
          ),
          RadioListTile(
            value: 'French',
            groupValue: _selectedLanguage,
            title: const Text("French"),
            onChanged: (val) => setState(() => _selectedLanguage = val!),
          ),
        ],
      ),
    );
  }
}