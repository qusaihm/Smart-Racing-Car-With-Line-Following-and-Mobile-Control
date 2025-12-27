 import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'saved_paths_screen.dart';

/// Model class for Path Points
class PathPoint {
  final DateTime timestamp;
  final int speed;
  final String action;
  final List<int> sensorValues;

  PathPoint({
    required this.timestamp,
    required this.speed,
    required this.action,
    required this.sensorValues,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'action': action,
      'sensors': sensorValues,
    };
  }

  static PathPoint fromMap(Map<String, dynamic> map) {
    return PathPoint(
      timestamp: DateTime.parse(map['timestamp']),
      speed: map['speed'],
      action: map['action'],
      sensorValues: List<int>.from(map['sensors']),
    );
  }
}

/// Statistic Card Widget
class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Main Record Path Screen
class RecordPathScreen extends StatefulWidget {
  final WebSocketChannel channel;

  const RecordPathScreen({super.key, required this.channel});

  @override
  State<RecordPathScreen> createState() => _RecordPathScreenState();
}

class _RecordPathScreenState extends State<RecordPathScreen> {
  // Recording state
  bool _isRecording = false;
  Timer? _timer;
  int _recordingTimeSeconds = 0;
  int _numberOfTurns = 0;
  double _averageSpeed = 0.0;
  int _totalSpeedSum = 0;
  int _speedReadings = 0;

  // Path data
  List<PathPoint> recordedPath = [];
  StreamSubscription? _webSocketSubscription;

  int _currentSpeed = 150;
  String _lastAction = 'STOP';
  String _currentStatus = 'Ready to record';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Format time (seconds to mm:ss)
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // Start recording
  Future<void> _startRecording() async {
    print('▶ Starting recording...');

    setState(() {
      _isRecording = true;
      _recordingTimeSeconds = 0;
      _numberOfTurns = 0;
      _averageSpeed = 0.0;
      _totalSpeedSum = 0;
      _speedReadings = 0;
      recordedPath.clear();
      _currentStatus = 'Sending command...';
      _lastAction = 'STOP';
    });

    try {
      widget.channel.sink.add('record_start');
      print('📤 Command sent: record_start');

      setState(() {
      _currentStatus = 'Recording started – waiting for sensor data...';
      });
    } catch (e) {
      print('❌ Failed to send record_start: $e');
      setState(() {
        _currentStatus = 'Command failed: $e';
        _isRecording = false;
      });
      return;
    }

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTimeSeconds++;
      });
    });

    // Listen to WebSocket messages
    _webSocketSubscription = widget.channel.stream.listen((message) {
      print('📩 Received: $message');

      if (!_isRecording) return;

      // Handle sensor data
      if (message.startsWith("SENSORS:")) {
        List<String> sensorStrs = message.substring(8).split(",");
        if (sensorStrs.length == 5) {
          List<int> sensorValues =
              sensorStrs.map((s) => int.tryParse(s) ?? 0).toList();

          // Add point
          recordedPath.add(PathPoint(
            timestamp: DateTime.now(),
            speed: _currentSpeed,
            action: _lastAction,
            sensorValues: sensorValues,
          ));

          // Update stats
          _totalSpeedSum += _currentSpeed;
          _speedReadings++;

          setState(() {
            _averageSpeed = _speedReadings > 0
                ? (_totalSpeedSum / _speedReadings) / 255 * 100
                : 0.0;

            _currentStatus = "Recording (${recordedPath.length} points)";

            // Count turns based on current action
            if (_lastAction == 'LEFT' || _lastAction == 'RIGHT') {
              _numberOfTurns++;
            }
          });

          print("✅ Point #${recordedPath.length} | Action: $_lastAction | Speed: $_currentSpeed");
        }
      }

      // Update action
      if (message.startsWith("ACTION:")) {
        _lastAction = message.substring(7);
        print('🔄 Action: $_lastAction');
      }

      // Update speed
      if (message.startsWith("SPEED:")) {
        _currentSpeed = int.tryParse(message.substring(6)) ?? _currentSpeed;
        print('⚡ Speed: $_currentSpeed');
      }

      // Update mode/status
      if (message.startsWith("MODE:")) {
        String mode = message.substring(5);
        setState(() {
          if (_currentStatus.startsWith('Waiting') || _currentStatus == 'Sending command...') {
            _currentStatus = 'Recording (${recordedPath.length} points)';
          }
        });
        print('📝 Mode: $mode');
      }
    });
  }

  // Stop recording and save
 Future<void> _stopRecording() async {
    if (!_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠ Not currently recording'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _currentStatus = 'Stopping robot...';
    });

    // 1. أرسل أوامر الإيقاف للـ ESP
    try {
      widget.channel.sink.add('record_stop');
      await Future.delayed(const Duration(milliseconds: 100));
      widget.channel.sink.add('stop');
      print('📤 Sent stop commands');
    } catch (e) {
      print('⚠ Failed to send stop commands: $e');
    }

    // 2. إيقاف المؤقت
    _timer?.cancel();

    setState(() {
      _currentStatus = 'Waiting for remaining data...';
    });

    // 3. انتظر وقت كافي لاستقبال كل البيانات المتبقية (مهم جداً!)
    await Future.delayed(const Duration(milliseconds: 1500)); // 1.5 ثانية كافية

    // 4. إلغاء الاشتراك في الـ WebSocket
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;

    setState(() {
      _isRecording = false;
      _currentStatus = 'Finalizing data...';
    });

    // 5. لو لسة مفيش نقاط، أضف نقطة أخيرة يدوياً (للأمان)
    if (recordedPath.isEmpty) {
      print('⚠ No points recorded, adding final fallback point');
      recordedPath.add(PathPoint(
        timestamp: DateTime.now(),
        speed: _currentSpeed,
        action: 'STOP',
        sensorValues: [2000, 2000, 2000, 2000, 2000],
      ));
      _totalSpeedSum += _currentSpeed;
      _speedReadings += 1;
    }

    // 6. تحديث الإحصائيات النهائية
    setState(() {
      if (_speedReadings > 0) {
        _averageSpeed = (_totalSpeedSum / _speedReadings) / 255 * 100;
      }
      _currentStatus = 'Saving path...';
    });

    // 7. حفظ في Firestore
    bool success = await _savePathToFirestore();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Path saved successfully! (${recordedPath.length} points)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {
        _currentStatus = 'Saved ✓ (${recordedPath.length} points)';
      });
      print('✅ Final saved points: ${recordedPath.length}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Save failed – check internet/Firestore rules'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save to Firestore
  Future<bool> _savePathToFirestore() async {
    try {
      String pathId = 'path_${DateTime.now().millisecondsSinceEpoch}';
      String now = DateTime.now().toIso8601String();

      Map<String, dynamic> pathData = {
        'id': pathId,
        'createdAt': now,
        'updatedAt': now,
        'duration': _recordingTimeSeconds,
        'totalPoints': recordedPath.length,
        'averageSpeed': _averageSpeed.round(),
        'numberOfTurns': _numberOfTurns,
        'pathPoints': recordedPath.map((p) => p.toMap()).toList(),
      };

      await _firestore.collection('recorded_paths').doc(pathId).set(pathData);
      print('✅ Saved to Firestore: ${recordedPath.length} points');
      return true;
    } catch (e) {
      print('❌ Firestore save failed: $e');
      return false;
    }
  }

  // Navigate to saved paths
  void _navigateToSavedPaths() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedPathsScreen(channel: widget.channel),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Path', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            onPressed: _navigateToSavedPaths,
            icon: const Icon(Icons.history),
            tooltip: 'Saved Paths',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRecording ? secondaryColor.withOpacity(0.1) : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isRecording ? secondaryColor : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRecording ? Icons.radio_button_checked : Icons.circle_outlined,
                    color: _isRecording ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRecording ? 'RECORDING ACTIVE' : 'READY TO RECORD',
                          style: TextStyle(
                            color: _isRecording ? Colors.green : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_currentStatus, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (_isRecording && recordedPath.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Points: ${recordedPath.length} | Speed: $_currentSpeed',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Recording Circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
                shape: BoxShape.circle,
                border: Border.all(color: _isRecording ? tertiaryColor : primaryColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording ? secondaryColor.withOpacity(0.5) : Colors.transparent,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isRecording ? Icons.radio_button_checked : Icons.route, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'LIVE' : 'READY',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text('$_recordingTimeSeconds s', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    if (recordedPath.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${recordedPath.length} points', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : _startRecording,
                    icon: const Icon(Icons.fiber_manual_record, size: 24),
                    label: const Text('START RECORDING', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.grey.shade800 : secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : null,
                    icon: const Icon(Icons.stop, size: 24),
                    label: const Text('STOP & SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? tertiaryColor : Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Firestore Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud, color: primaryColor, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Firestore Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('recorded_paths').snapshots(),
                          builder: (context, snapshot) {
                            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return Text('Total saved paths: $count', style: const TextStyle(color: Colors.white70));
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _navigateToSavedPaths, icon: Icon(Icons.arrow_forward, color: primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Statistics
            const Text('RECORDING STATISTICS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _StatisticCard(icon: Icons.turn_right, label: 'Number of Turns', value: _numberOfTurns.toString(), color: primaryColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _StatisticCard(icon: Icons.timer, label: 'Recording Time', value: _formatTime(_recordingTimeSeconds), color: secondaryColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _StatisticCard(icon: Icons.speed, label: 'Average Speed', value: '${_averageSpeed.round()}%', color: tertiaryColor.withOpacity(0.7)),
            if (recordedPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              _StatisticCard(icon: Icons.analytics, label: 'Total Points', value: recordedPath.length.toString(), color: Colors.purple.withOpacity(0.7)),
            ],
            const SizedBox(height: 40),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text('Recording Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording
                        ? '• Recording in progress - ${recordedPath.length} points captured\n'
                          '• Data will be saved to Firestore when you stop\n'
                          '• View saved paths via the history button'
                        : '• Press START RECORDING to begin\n'
                          '• The robot will follow the line and record every movement\n'
                          '• All data is automatically saved to the cloud',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}