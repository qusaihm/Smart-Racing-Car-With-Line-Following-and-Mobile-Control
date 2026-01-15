 import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'theme.dart';
import 'dashboard_screen.dart';
import 'ws_connection.dart';

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  WsConnection? connection;

  bool isConnected = false;
  String ipAddress = "192.168.1.1";
  final int port = 81;
  final TextEditingController _ipController = TextEditingController();
  bool isLoading = false;

  StreamSubscription? _connectSub;

  @override
  void initState() {
    super.initState();
    _ipController.text = ipAddress;
  }

  Future<void> connectToESP() async {
    // ✅ Close old connection if exists
    if (connection != null) {
      try {
        await _connectSub?.cancel();
        await connection!.close(status.goingAway);
      } catch (_) {}
      connection = null;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('ws://$ipAddress:$port');
      print("🔌 Connecting to $uri");

      final ch = WebSocketChannel.connect(uri);
      final conn = WsConnection(channel: ch);

      // ✅ Listen to handshake / status using broadcast stream
      _connectSub = conn.stream.listen(
        (message) {
          final msg = message.toString();
          print("📩 ESP32: $msg");

          if (msg.contains("CONNECTED:ESP32_READY")) {
            if (!mounted) return;
            setState(() {
              isConnected = true;
              isLoading = false;
              connection = conn;
            });
            _showSnackBar('✅ Connected to ESP32', Colors.green);

            // ✅ Optional: ask for status right after connect
            try {
              conn.send("get_status");
            } catch (_) {}
          }
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            isConnected = false;
            isLoading = false;
            connection = null;
          });
          _showSnackBar('⚠ Connection closed', Colors.orange);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            isConnected = false;
            isLoading = false;
            connection = null;
          });
          _showSnackBar('❌ Connection error', Colors.red);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isConnected = false;
        isLoading = false;
        connection = null;
      });
      _showSnackBar('❌ Failed to connect: $e', Colors.red);
    }
  }

  Future<void> disconnectFromESP() async {
    if (connection != null) {
      try {
        await _connectSub?.cancel();
        await connection!.close(status.goingAway);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        isConnected = false;
        isLoading = false;
        connection = null;
      });
      _showSnackBar('🔌 Disconnected from ESP32', Colors.blue);
    }
  }

  void _goToDashboard() {
    if (connection != null && isConnected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(connection: connection!),
        ),
      );
    } else {
      _showSnackBar('⚠ Please connect to device first', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _connectSub?.cancel();
    // ✅ لا تغلق connection هنا لأنك ممكن تنتقل للـ Dashboard وهي لسه مستخدمة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Connect to Your Car',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your car\'s IP address to establish connection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'ESP32 IP Address',
                hintText: '192.168.1.1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(Icons.computer, color: secondaryColor),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  ipAddress = value.trim();
                });
              },
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
                      'Make sure your phone and car are on the same WiFi network',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : (isConnected ? disconnectFromESP : connectToESP),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isConnected ? Icons.wifi_off : Icons.wifi,
                      size: 24,
                    ),
              label: isLoading
                  ? const Text('Connecting...')
                  : Text(isConnected ? 'Disconnect' : 'Connect to Device'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: isConnected
                    ? tertiaryColor
                    : (isLoading ? Colors.grey.shade700 : primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (isConnected) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _goToDashboard,
                icon: const Icon(Icons.dashboard, color: Colors.white, size: 24),
                label: const Text('Go to Dashboard'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            if (isConnected || isLoading) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? secondaryColor.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? secondaryColor : primaryColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle : Icons.sync,
                        color: isConnected ? secondaryColor : primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? 'Connected Successfully' : 'Connecting...',
                        style: TextStyle(
                          color: isConnected ? secondaryColor : primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Troubleshooting Tips:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '• Check if devices are on same WiFi\n• Verify the IP address is correct\n• Ensure car is powered on',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}