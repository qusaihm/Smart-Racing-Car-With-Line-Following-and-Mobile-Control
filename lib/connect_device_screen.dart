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
  bool isLoading = false;

  String ipAddress = "192.168.1.1";
  final int port = 81;
  final TextEditingController _ipController = TextEditingController();

  StreamSubscription? _connectSub;

  @override
  void initState() {
    super.initState();
    _ipController.text = ipAddress;
  }

  Future<void> connectToESP() async {
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
      final ch = WebSocketChannel.connect(uri);
      final conn = WsConnection(channel: ch);

      _connectSub = conn.stream.listen(
        (message) {
          final msg = message.toString();
          if (msg.contains("CONNECTED:ESP32_READY")) {
            if (!mounted) return;
            setState(() {
              isConnected = true;
              isLoading = false;
              connection = conn;
            });
            _showSnack('✅ Connected to ESP32', Colors.green);
            try {
              conn.send("get_status");
            } catch (_) {}
          }
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
      _showSnack('❌ Failed to connect', Colors.red);
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;
    setState(() {
      isConnected = false;
      isLoading = false;
      connection = null;
    });
  }

  Future<void> disconnectFromESP() async {
    try {
      await _connectSub?.cancel();
      await connection?.close(status.goingAway);
    } catch (_) {}
    _handleDisconnect();
    _showSnack('🔌 Disconnected', Colors.blue);
  }

  void _goToDashboard() {
    if (connection != null && isConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(connection: connection!),
        ),
      );
    } else {
      _showSnack('⚠ Please connect first', Colors.orange);
    }
  }

  void _showSnack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Device",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect to Your Smart Car',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter ESP32 IP address to establish connection',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP Address',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: backgroundColor,
                      prefixIcon:
                          const Icon(Icons.computer, color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => ipAddress = v.trim(),
                  ),

                  const SizedBox(height: 20),

                 SizedBox(
  height: 58,
  child: ElevatedButton(
    onPressed: isLoading
        ? null
        : (isConnected ? disconnectFromESP : connectToESP),
    style: ElevatedButton.styleFrom(
      backgroundColor: isConnected ? tertiaryColor : primaryColor,
      foregroundColor: Colors.white, // ✅ النص أبيض دائمًا
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else
          Icon(
            isConnected ? Icons.link_off : Icons.link,
            size: 26,
            color: Colors.white,
          ),
        const SizedBox(width: 12),
        Text(
          isLoading
              ? 'Connecting...'
              : (isConnected ? 'Disconnect' : 'Connect'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),

                  if (isConnected) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _goToDashboard,
                        icon: const Icon(Icons.dashboard),
                        label: const Text(
                          'Go to Dashboard',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isConnected
                    ? secondaryColor.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isConnected ? secondaryColor : primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.sync,
                    color: isConnected ? secondaryColor : primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isConnected ? 'Connected Successfully' : 'Waiting...',
                    style: TextStyle(
                      color: isConnected ? secondaryColor : primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Troubleshooting',
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              '• Same WiFi network\n• Correct IP address\n• Car powered ON',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _connectSub?.cancel();
    super.dispose();
  }
}