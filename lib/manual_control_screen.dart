import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme.dart';
import 'settings_screen.dart';

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
  final WebSocketChannel channel;

  const ManualControlScreen({super.key, required this.channel});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  double _currentSpeedPercentage = 50;
  bool _isEngineRunning = false;
  final int _batteryLevel = 85;
  bool _isConnected = true;
  int _currentSpeed = 150; // السرعة الفعلية المرسلة للـ ESP

  double get _simulatedSpeedKmH => (_currentSpeed * 0.07).clamp(0, 7);

  void _sendCommand(String command) {
    if (_isConnected) {
      try {
        widget.channel.sink.add(command);
        print('📤 Sent Command: $command');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Command Sent: $command'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            )
        );
      } catch (e) {
        print('❌ Error sending command: $e');
        setState(() => _isConnected = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection Lost: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not connected to device'),
            backgroundColor: Colors.orange,
          )
      );
    }

    // تحديث حالة المحرك بناءً على الأوامر
    if (command == 'start') {
      setState(() => _isEngineRunning = true);
    } else if (command == 'stop') {
      setState(() => _isEngineRunning = false);
    }
  }

  void _updateSpeed(double value) {
    setState(() {
      _currentSpeedPercentage = value;
      // تحويل النسبة المئوية إلى قيمة سرعة بين 0-255
      _currentSpeed = ((value / 100) * 255).round();
    });

    // إرسال أمر السرعة فوراً عند التغيير
    _sendCommand('speed:$_currentSpeed');
  }

  @override
  void initState() {
    super.initState();

    try {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          widget.channel.stream.listen(
                (message) {
              print("📩 Message from ESP32: $message");
              if (mounted) {
                setState(() {
                  _isConnected = true;
                });

                // معالجة الرسائل الواردة من الـ ESP32
                if (message == "Connected") {
                  setState(() => _isConnected = true);
                } else if (message.startsWith("MODE:")) {
                  setState(() {
                    _isEngineRunning = message.contains("Started");
                  });
                } else if (message.startsWith("SPEED:")) {
                  // تحديث السرعة عند استلام تأكيد من الـ ESP32
                  try {
                    int newSpeed = int.tryParse(message.split(":")[1]) ?? _currentSpeed;
                    setState(() {
                      _currentSpeed = newSpeed;
                      _currentSpeedPercentage = ((newSpeed / 255) * 100).roundToDouble();
                    });
                  } catch (e) {
                    print('❌ Error parsing speed: $e');
                  }
                }
              }
            },
            onDone: () {
              print("Connection closed by server");
              if (mounted) {
                setState(() => _isConnected = false);
              }
            },
            onError: (error) {
              print("Connection error: $error");
              if (mounted) {
                setState(() => _isConnected = false);
              }
            },
          );
        }
      });
    } catch (e) {
      print("❌ Error setting up stream listener: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remote Control', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings, color: Colors.white),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? secondaryColor.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
                  SizedBox(width: 8),
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
            SizedBox(height: 20),

            Text('Remote Control',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                )),
            SizedBox(height: 30),

            // 🚗 ENGINE CONTROL BUTTON
            _ControlCard(
              children: [
                Text('Engine Control',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _isConnected
                      ? () {
                    _sendCommand(_isEngineRunning ? 'stop' : 'start');
                  }
                      : null,
                  icon: Icon(
                    _isEngineRunning ? Icons.power_settings_new : Icons.play_arrow,
                    size: 28,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isEngineRunning ? 'STOP Engine' : 'START Engine',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEngineRunning ? tertiaryColor : secondaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
                SizedBox(height: 10),
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
            SizedBox(height: 30),

            // 🎚 SPEED CONTROL SECTION
            _ControlCard(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Speed Control',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currentSpeedPercentage.round()}%',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          ),
                        ),
                        Text(
                          '$_currentSpeed/255',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Speed Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12.0,
                    thumbShape: RoundSliderThumbShape(
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
                    divisions: 20, // 5% increments
                    label: '${_currentSpeedPercentage.round()}%',
                    onChanged: _isConnected ? (double value) {
                      _updateSpeed(value);
                    } : null,
                  ),
                ),

                // Speed Percentage Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('25%', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('50%', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('75%', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('100%', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                SizedBox(height: 15),

                // Speed Preset Buttons
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
            SizedBox(height: 30),

            // 📊 VEHICLE STATUS
            _ControlCard(
              children: [
                Text('Vehicle Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                SizedBox(height: 20),

                // Engine Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isEngineRunning ? secondaryColor : tertiaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Engine Status', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(
                              _isEngineRunning ? 'RUNNING' : 'STOPPED',
                              style: TextStyle(
                                color: _isEngineRunning ? secondaryColor : tertiaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Battery Status
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Battery Level', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(
                              '$_batteryLevel%',
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.battery_full, color: secondaryColor, size: 24),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),
                Divider(color: Colors.white24),
                SizedBox(height: 15),

                // Connection & Speed Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connection', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                        Text('Current Speed', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          '$_currentSpeed',
                          style: TextStyle(
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

            SizedBox(height: 20),

            // ℹ INFORMATION SECTION
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
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

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // زر السرعة المسبقة الإعداد
  Widget _buildSpeedPresetButton(String label, int speedPercentage) {
    return ElevatedButton(
      onPressed: _isConnected ? () {
        _updateSpeed(speedPercentage.toDouble());
      } : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(60, 40),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
