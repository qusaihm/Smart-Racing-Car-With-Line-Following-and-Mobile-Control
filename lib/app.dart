import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';
import 'connect_device_screen.dart';
import 'manual_control_screen.dart';
import 'dashboard_screen.dart';
import 'record_path_screen.dart';
import 'settings_screen.dart';
import 'saved_paths_screen.dart';

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
      
      onGenerateRoute: (settings) {
        // صفحة Manual Control
        if (settings.name == '/manual') {
          final channel = settings.arguments as WebSocketChannel;
          return MaterialPageRoute(
            builder: (_) => ManualControlScreen(channel: channel),
          );
        }
        
        // صفحة Dashboard
        if (settings.name == '/dashboard') {
          final channel = settings.arguments as WebSocketChannel;
          return MaterialPageRoute(
            builder: (_) => DashboardScreen(channel: channel),
          );
        }
        
        // صفحة Record Path
        if (settings.name == '/record') {
          final channel = settings.arguments as WebSocketChannel;
          return MaterialPageRoute(
            builder: (_) => RecordPathScreen(channel: channel),
          );
        }
        
        // صفحة Saved Paths
        if (settings.name == '/saved-paths') {
          final channel = settings.arguments as WebSocketChannel;
          return MaterialPageRoute(
            builder: (_) => SavedPathsScreen(channel: channel),
          );
        }
        
        return null;
      },
    );
  }
}
