import 'package:flutter/material.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';
import 'connect_device_screen.dart';
import 'settings_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Line Follower Car',
      theme: appTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create': (context) => const CreateAccountScreen(),
        '/connect': (context) => const ConnectDeviceScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      
    );
  }
}