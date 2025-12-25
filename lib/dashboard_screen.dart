import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme.dart';
import 'manual_control_screen.dart';
import 'record_path_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final WebSocketChannel channel;

  const DashboardScreen({super.key, required this.channel});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isConnected = true;
  int _batteryLevel = 85;
  bool _isEngineRunning = false;
  String _drivingMode = 'Manual';

  // ------------------------------
  // Status Card (Battery / Engine / Mode)
  // ------------------------------
  Widget _statusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.9),
            cardColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: title == "Battery Level"
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: color, size: 38),
                ),

                const SizedBox(height: 14),

                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),

                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ------------------------------
  // Action Buttons
  // ------------------------------
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
            color.withOpacity(0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.45), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // Connection Status
  // ------------------------------
  Widget _connectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected
            ? secondaryColor.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isConnected ? secondaryColor : Colors.red,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _isConnected ? secondaryColor : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: _isConnected ? secondaryColor : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // BUILD
  // ------------------------------
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

              // ------------------ HEADER ------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),

                  _connectionStatus(),

                  // Settings Icon
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // TITLE
              const Text(
                'Smart Line\nFollower',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Monitor and control your robot in real-time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------ STATUS CARDS ------------------
              SizedBox(
                height: 280,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _statusCard(
                        icon: Icons.battery_charging_full_rounded,
                        title: 'Battery Level',
                        value: '$_batteryLevel%',
                        color: secondaryColor,
                        isWide: true,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _statusCard(
                              icon: Icons.speed_rounded,
                              title: 'Engine',
                              value: _isEngineRunning ? 'ON' : 'OFF',
                              color: _isEngineRunning
                                  ? secondaryColor
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _statusCard(
                              icon: Icons.sports_esports_outlined,
                              title: 'Mode',
                              value: _drivingMode,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // ------------------ Controls Title ------------------
              Row(
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.tune,
                      color: Colors.white.withOpacity(0.5), size: 20),
                ],
              ),

              const SizedBox(height: 20),

              // Remote Control
              _actionButton(
                title: 'Remote Control',
                subtitle: 'Manual joystick interface',
                icon: Icons.gamepad,
                color: primaryColor,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ManualControlScreen(channel: widget.channel),
                  ),
                ),
              ),

              // Path Recording - الإصلاح هنا!
              _actionButton(
                title: 'Path Recording',
                subtitle: 'Record and save track data',
                icon: Icons.timeline,
                color: secondaryColor,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecordPathScreen(channel: widget.channel),
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