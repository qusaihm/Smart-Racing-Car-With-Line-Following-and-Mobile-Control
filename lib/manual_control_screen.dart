 import 'package:flutter/material.dart';
import 'dart:async';
import 'theme.dart';
import 'ws_connection.dart';

class _ControlCard extends StatelessWidget {
  final List<Widget> children;
  const _ControlCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class ManualControlScreen extends StatefulWidget {
  final WsConnection connection;

  const ManualControlScreen({super.key, required this.connection});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  double _currentSpeedPercentage = 50;
  bool _isEngineRunning = false;
  final int _batteryLevel = 85;
  bool _isConnected = true;

  int _currentSpeed = 150;

  StreamSubscription? _wsSub;

  void _sendCommand(String command, {bool showToast = true}) {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      widget.connection.send(command);
      print('📤 Sent Command: $command');

      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command Sent: $command'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error sending command: $e');
      if (!mounted) return;
      setState(() => _isConnected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection Lost: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (command == 'start') {
      setState(() => _isEngineRunning = true);
    } else if (command == 'stop') {
      setState(() => _isEngineRunning = false);
    }
  }

  void _updateSpeedUI(double value) {
    setState(() {
      _currentSpeedPercentage = value;
      _currentSpeed = ((value / 100) * 255).round().clamp(0, 255);
    });
  }

  void _sendSpeedToESP() {
    _sendCommand('speed:$_currentSpeed', showToast: false);
  }

  @override
  void initState() {
    super.initState();

    _wsSub = widget.connection.stream.listen(
      (message) {
        final msg = message.toString();
        print("📩 Message from ESP32: $msg");

        if (!mounted) return;
        setState(() => _isConnected = true);

        

        if (msg.startsWith("SPEED:")) {
          final newSpeed = int.tryParse(msg.substring(6).trim());
          if (newSpeed != null) {
            setState(() {
              _currentSpeed = newSpeed.clamp(0, 255);
              _currentSpeedPercentage =
                  ((_currentSpeed / 255) * 100).clamp(0, 100);
            });
          }
        } else if (msg.contains("CONNECTED:ESP32_READY")) {
          setState(() => _isConnected = true);
        }
      },
      onDone: () {
        print("⚠ Connection closed by server");
        if (!mounted) return;
        setState(() => _isConnected = false);
      },
      onError: (error) {
        print("❌ Connection error: $error");
        if (!mounted) return;
        setState(() => _isConnected = false);
      },
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      try {
        widget.connection.send('get_status');
      } catch (e) {
        print("⚠ get_status send failed: $e");
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  // ==========================
  // Battery UI Helpers
  // ==========================
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

  Widget _statusTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batteryTile() {
    final c = _batteryColor();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_batteryIcon(), color: c, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Battery',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        '$_batteryLevel%',
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _batteryLevel / 100,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // BUILD
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Control',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Connection Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected
                    ? secondaryColor.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected ? secondaryColor : Colors.red,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _isConnected ? secondaryColor : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Connected to Device' : 'Disconnected',
                    style: TextStyle(
                      color: _isConnected ? secondaryColor : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Remote Control',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 30),

            // ENGINE CONTROL
            _ControlCard(
              children: [
                const Text('Engine Control',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _isConnected
                      ? () => _sendCommand(_isEngineRunning ? 'stop' : 'start')
                      : null,
                  icon: Icon(
                    _isEngineRunning
                        ? Icons.power_settings_new
                        : Icons.play_arrow,
                    size: 28,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isEngineRunning ? 'STOP Engine' : 'START Engine',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isEngineRunning ? tertiaryColor : secondaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isEngineRunning
                      ? '🟢 Engine is running - Car is active'
                      : '🔴 Engine is stopped - Car is idle',
                  style: TextStyle(
                    color: _isEngineRunning ? secondaryColor : Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // SPEED CONTROL
            _ControlCard(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Speed Control',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currentSpeedPercentage.round()}%',
                          style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        Text(
                          '$_currentSpeed/255',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 14.0,
                      disabledThumbRadius: 10.0,
                    ),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: primaryColor.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: primaryColor.withOpacity(0.2),
                    valueIndicatorColor: primaryColor,
                    showValueIndicator: ShowValueIndicator.onDrag,
                  ),
                  child: Slider(
                    value: _currentSpeedPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_currentSpeedPercentage.round()}%',
                    onChanged: _isConnected ? _updateSpeedUI : null,
                    onChangeEnd: _isConnected
                        ? (v) {
                            _updateSpeedUI(v);
                            _sendSpeedToESP();
                          }
                        : null,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0%',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('25%',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('50%',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('75%',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('100%',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSpeedPresetButton('Slow', 25),
                    _buildSpeedPresetButton('Medium', 50),
                    _buildSpeedPresetButton('Fast', 75),
                    _buildSpeedPresetButton('Max', 100),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // VEHICLE STATUS (UPDATED UI)
            _ControlCard(
              children: [
                const Text('Vehicle Status',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                const SizedBox(height: 18),

                Row(
                  children: [
                    _statusTile(
                      title: 'Engine',
                      value: _isEngineRunning ? 'RUNNING' : 'STOPPED',
                      icon: _isEngineRunning
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _isEngineRunning
                          ? secondaryColor
                          : tertiaryColor,
                    ),
                    const SizedBox(width: 12),
                    _batteryTile(),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connection',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(
                          _isConnected ? 'ACTIVE' : 'LOST',
                          style: TextStyle(
                            color: _isConnected ? secondaryColor : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Current Speed',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(
                          '$_currentSpeed',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Speed range: 0-255 (PWM values). Higher values = faster movement.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedPresetButton(String label, int speedPercentage) {
    return ElevatedButton(
      onPressed: _isConnected
          ? () {
              _updateSpeedUI(speedPercentage.toDouble());
              _sendSpeedToESP();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 40),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}