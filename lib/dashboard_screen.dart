 import 'package:flutter/material.dart';
import 'theme.dart';

import 'ws_connection.dart';
import 'manual_control_screen.dart';
import 'record_path_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final WsConnection connection;

  const DashboardScreen({super.key, required this.connection});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final bool _isConnected = true;
  final int _batteryLevel = 85;
  final bool _isEngineRunning = false;
  final String _drivingMode = 'Manual';

  Color _batteryColor() {
    if (_batteryLevel > 60) return Colors.greenAccent;
    if (_batteryLevel > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  IconData _batteryIcon() {
    if (_batteryLevel > 80) return Icons.battery_full;
    if (_batteryLevel > 50) return Icons.battery_5_bar;
    if (_batteryLevel > 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }

  Widget _batteryCard() {
    final color = _batteryColor();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            cardColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_batteryIcon(), color: color, size: 52),
          const SizedBox(height: 14),
          Text(
            '$_batteryLevel%',
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Battery Level',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _batteryLevel / 100,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white60)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ONLINE',
            style: TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.grid_view, color: Colors.white70),
                  _connectionStatus(),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Smart Line Follower',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Real-time monitoring & control dashboard',
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(flex: 4, child: _batteryCard()),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _statusMiniCard(
                          icon: Icons.speed,
                          title: 'Engine',
                          value: _isEngineRunning ? 'ON' : 'OFF',
                          color: _isEngineRunning
                              ? secondaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        _statusMiniCard(
                          icon: Icons.gamepad,
                          title: 'Mode',
                          value: _drivingMode,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'Controls',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),

              const SizedBox(height: 20),

              _actionButton(
                title: 'Remote Control',
                subtitle: 'Manual driving interface',
                icon: Icons.gamepad,
                color: primaryColor,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManualControlScreen(connection: widget.connection),
                  ),
                ),
              ),

              _actionButton(
                title: 'Path Recording',
                subtitle: 'Record and replay routes',
                icon: Icons.timeline,
                color: secondaryColor,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecordPathScreen(connection: widget.connection),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}