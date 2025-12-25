import 'package:flutter/material.dart';
import 'theme.dart';

class DefaultSpeedSettings extends StatefulWidget {
  const DefaultSpeedSettings({super.key});

  @override
  State<DefaultSpeedSettings> createState() => _DefaultSpeedSettingsState();
}

class _DefaultSpeedSettingsState extends State<DefaultSpeedSettings> {
  double _speed = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Default Speed")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Set your default car speed:",
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _speed,
              min: 0,
              max: 100,
              divisions: 10,
              label: "${_speed.round()}%",
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _speed = val),
            ),
            Text("Current speed: ${_speed.toInt()}%"),
          ],
        ),
      ),
    );
  }
}