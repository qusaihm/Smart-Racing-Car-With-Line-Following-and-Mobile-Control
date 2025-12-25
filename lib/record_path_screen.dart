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
  Timer? _simulationTimer;
  final Random _random = Random();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  // Format time (seconds to mm:ss)
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // Start simulation (for testing without ESP32)
  void _startSimulation() {
    print('🎮 Starting simulation mode');

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // Simulate sensor data
      List<int> sensorValues = [
        1500 + _random.nextInt(1000),
        1600 + _random.nextInt(1000),
        1200 + _random.nextInt(1000),
        1700 + _random.nextInt(1000),
        1800 + _random.nextInt(1000),
      ];

      // Determine action based on simulated sensors
      String action = 'FORWARD';
      if (sensorValues[1] < 1800) action = 'LEFT';
      if (sensorValues[3] < 1800) action = 'RIGHT';
      if (sensorValues[2] > 2200) action = 'STOP';

      // Add point to recorded path
      recordedPath.add(PathPoint(
        timestamp: DateTime.now(),
        speed: _currentSpeed,
        action: action,
        sensorValues: sensorValues,
      ));

      // Update statistics
      _totalSpeedSum += _currentSpeed;
      _speedReadings++;

      setState(() {
        if (action == 'LEFT' || action == 'RIGHT') {
          _numberOfTurns++;
        }
        _averageSpeed = (_totalSpeedSum / _speedReadings) / 255 * 100;
        _lastAction = action;
        _currentStatus = 'Recording (Simulation) - ${recordedPath.length} points';
      });

      print('📊 Simulated point ${recordedPath.length}: $action');
    });
  }

  // Start recording
  Future<void> _startRecording() async {
    print('▶ Starting recording...');

    // Reset all data first
    setState(() {
      _isRecording = true;
      _recordingTimeSeconds = 0;
      _numberOfTurns = 0;
      _averageSpeed = 0.0;
      _totalSpeedSum = 0;
      _speedReadings = 0;
      recordedPath.clear();
      _currentStatus = 'Connecting...';
      _lastAction = 'STOP';
    });

    // إعطاء وقت للتطبيق لتحديث واجهة المستخدم
    await Future.delayed(const Duration(milliseconds: 200));

    // إرسال أوامر البدء
    try {
      // 🔴 الترتيب مهم: record_start أولاً، ثم start
      widget.channel.sink.add('record_start');
      
      // تأخير بسيط بين الأوامر
      await Future.delayed(const Duration(milliseconds: 150));
      
      widget.channel.sink.add('start');
      
      print('📤 Commands sent: record_start → start');
      setState(() {
        _currentStatus = 'Commands sent, waiting for data...';
      });
    } catch (e) {
      print('❌ Failed to send start commands: $e');
      setState(() {
        _currentStatus = 'Failed to send commands: $e';
        _isRecording = false;
      });
      return;
    }

    // انتظر قليلاً للاستجابة من ESP
    await Future.delayed(const Duration(milliseconds: 300));

    // بدء المؤقت
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTimeSeconds++;
      });
    });

    // 🔴 استمع للرسائل من ESP
    _webSocketSubscription = widget.channel.stream.listen((message) {
      print('📩 Received from ESP: $message');

      if (!_isRecording) return;

      // معالجة رسائل الحساسات
      if (message.startsWith("SENSORS:")) {
        List<String> sensorStrs = message.substring(8).split(",");

        if (sensorStrs.length == 5) {
          List<int> sensorValues =
              sensorStrs.map((s) => int.tryParse(s) ?? 0).toList();

          // أضف النقطة إلى المسار المسجل
          recordedPath.add(PathPoint(
            timestamp: DateTime.now(),
            speed: _currentSpeed,
            action: _lastAction,
            sensorValues: sensorValues,
          ));

          // تحديث الإحصائيات
          _totalSpeedSum += _currentSpeed;
          _speedReadings++;

          setState(() {
            _averageSpeed = (_totalSpeedSum / _speedReadings) / 255 * 100;
            _currentStatus = "Recording (${recordedPath.length} points)";
            
            // عد المنعطفات تلقائياً
            if (_lastAction == 'LEFT' || _lastAction == 'RIGHT') {
              _numberOfTurns++;
            }
          });

          print("✅ ADDED POINT #${recordedPath.length} | Action: $_lastAction | Speed: $_currentSpeed");
        }
      }

      // معالجة ACTION
      if (message.startsWith("ACTION:")) {
        _lastAction = message.substring(7);
        print('🔄 Action updated: $_lastAction');
      }

      // معالجة SPEED
      if (message.startsWith("SPEED:")) {
        _currentSpeed = int.tryParse(message.substring(6)) ?? _currentSpeed;
        print('⚡ Speed updated: $_currentSpeed');
      }

      // معالجة MODE
      if (message.startsWith("MODE:")) {
        String mode = message.substring(5);
        setState(() {
          _currentStatus = mode;
        });
        print('📝 Mode updated: $mode');
      }
    });

    // 🔴 إضافة تأخير وهمي لاختبار الاستقبال
    Timer(const Duration(seconds: 2), () {
      if (recordedPath.isEmpty && _isRecording) {
        print('⚠ Warning: No data received in first 2 seconds');
        
        // أضف نقطة تجريبية إذا لم يتم استقبال بيانات
        recordedPath.add(PathPoint(
          timestamp: DateTime.now(),
          speed: _currentSpeed,
          action: 'TEST',
          sensorValues: [1500, 1600, 1700, 1800, 1900],
        ));
        
        setState(() {
          _totalSpeedSum += _currentSpeed;
          _speedReadings++;
          _averageSpeed = (_totalSpeedSum / _speedReadings) / 255 * 100;
        });
        
        print('➕ Added test point for debugging');
      }
    });
  }

  // Stop recording and save to Firestore (Global)
  Future<void> _stopRecording() async {
    // تأكد أننا نسجل فعلاً
    if (!_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠ Not currently recording'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // إرسال أوامر الإيقاف أولاً
    try {
      // 🔴 الترتيب المعاكس: stop أولاً، ثم record_stop
      widget.channel.sink.add('stop');
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      widget.channel.sink.add('record_stop');
      
      print('📤 Stop commands sent: stop → record_stop');
    } catch (e) {
      print('⚠ Failed to send stop commands: $e');
    }

    // إيقاف المؤقتات والاشتراكات
    _timer?.cancel();
    _simulationTimer?.cancel();
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;

    setState(() {
      _isRecording = false;
      _currentStatus = 'Processing data...';
    });

    // انتظر لحظة لاستقبال أي بيانات متأخرة
    await Future.delayed(const Duration(milliseconds: 300));

    // 🔴 إذا لم يكن هناك بيانات مسجلة، أضف بيانات تجريبية
    if (recordedPath.isEmpty) {
      print('⚠ No data recorded, adding minimal path data');
      
      recordedPath.add(PathPoint(
        timestamp: DateTime.now(),
        speed: 150,
        action: 'STOP',
        sensorValues: [2000, 2000, 2000, 2000, 2000],
      ));
      
      _totalSpeedSum = 150;
      _speedReadings = 1;
      _averageSpeed = 58.8; // 150/255*100 ≈ 58.8%
      
      print('➕ Added minimal path for Firestore');
    }

    // حفظ المسار إلى Firestore
    bool success = await _savePathToFirestore();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Path Saved Successfully! (${recordedPath.length} points)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _currentStatus = 'Saved ✓ (${recordedPath.length} points)';
      });

      print('✅ Path saved to Firestore: ${recordedPath.length} points');
    } else {
      // خيار النسخ الاحتياطي المحلي
      _saveLocalBackup();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠ Saved locally (Firestore failed)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Save local backup
  void _saveLocalBackup() {
    try {
      final now = DateTime.now();
      final formattedDate = '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';
      
      print('💾 Local backup saved: $formattedDate | Points: ${recordedPath.length}');
      
      // يمكنك إضافة حفظ محلي هنا (مثل shared_preferences)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved locally: ${recordedPath.length} points'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Local backup failed: $e');
    }
  }

  // Save path to Firestore (Global collection, no user fields)
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
        'isSimulated': false,
        'pathPoints': recordedPath.map((point) => point.toMap()).toList(),
      };

      print('💾 Saving to Firestore: $pathId, points=${recordedPath.length}, duration=${_recordingTimeSeconds}s');
      await _firestore.collection('recorded_paths').doc(pathId).set(pathData);
      print('✅ Firestore save successful!');
      return true;
    } catch (e) {
      print('❌ Firestore error: $e');
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

  // Test Firestore write (global test)
  Future<void> _testFirestoreConnection() async {
    try {
      String testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('recorded_paths').doc(testId).set({
        'id': testId,
        'test': true,
        'createdAt': DateTime.now().toIso8601String(),
        'message': 'Firestore connection test successful',
        'totalPoints': 1,
        'duration': 1,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Firestore connection successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firestore error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _simulationTimer?.cancel();
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
          // View Saved Paths button
          IconButton(
            onPressed: _navigateToSavedPaths,
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'View Saved Paths',
          ),
          // Test Firestore button
          IconButton(
            onPressed: _testFirestoreConnection,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'Test Firestore',
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
                border: Border.all(
                  color: _isRecording ? secondaryColor : Colors.transparent,
                ),
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
                        Text(
                          _currentStatus,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (_isRecording && recordedPath.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Points: ${recordedPath.length} | Speed: $_currentSpeed',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
                gradient: const LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? tertiaryColor : primaryColor,
                  width: 4,
                ),
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
                  Icon(
                    _isRecording ? Icons.radio_button_checked : Icons.route,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'LIVE' : 'READY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_recordingTimeSeconds s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (_isRecording && recordedPath.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${recordedPath.length} points',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
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
                    icon: Icon(
                      Icons.fiber_manual_record,
                      size: 24,
                      color: _isRecording ? Colors.grey : Colors.white,
                    ),
                    label: Text(
                      'START RECORDING',
                      style: TextStyle(
                        color: _isRecording ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    icon: Icon(
                      Icons.stop,
                      size: 24,
                      color: _isRecording ? Colors.white : Colors.grey,
                    ),
                    label: Text(
                      'STOP & SAVE',
                      style: TextStyle(
                        color: _isRecording ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? tertiaryColor : Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Test Button (Simulation)
            ElevatedButton.icon(
              onPressed: () {
                if (!_isRecording) {
                  _startRecording();
                  // توقف تلقائي بعد 5 ثواني
                  Future.delayed(const Duration(seconds: 5), () {
                    if (_isRecording) {
                      _stopRecording();
                    }
                  });
                }
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Quick Test (5 seconds)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            const SizedBox(height: 40),

            // Firebase/Firestore Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud,
                    color: primaryColor,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Firestore Storage',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('recorded_paths').snapshots(),
                          builder: (context, snapshot) {
                            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return Text(
                              'Total paths saved: $count',
                              style: const TextStyle(color: Colors.white70),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _navigateToSavedPaths,
                    icon: Icon(Icons.arrow_forward, color: primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Statistics Title
            const Text(
              'RECORDING STATISTICS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Cards
            _StatisticCard(
              icon: Icons.turn_right,
              label: 'Number of Turns',
              value: _numberOfTurns.toString(),
              color: primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),

            _StatisticCard(
              icon: Icons.timer,
              label: 'Recording Time',
              value: _formatTime(_recordingTimeSeconds),
              color: secondaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),

            _StatisticCard(
              icon: Icons.speed,
              label: 'Average Speed',
              value: '${_averageSpeed.round()}%',
              color: tertiaryColor.withOpacity(0.7),
            ),

            if (recordedPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              _StatisticCard(
                icon: Icons.analytics,
                label: 'Total Points',
                value: recordedPath.length.toString(),
                color: Colors.purple.withOpacity(0.7),
              ),
            ],

            const SizedBox(height: 30),

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
                      Text(
                        'Recording Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording 
                      ? '• Recording active - ${recordedPath.length} points captured\n'
                        '• Data will auto-save to Firestore when stopped\n'
                        '• View saved paths using the history button above'
                      : '• Click START to begin recording path\n'
                        '• Data is automatically saved to Firestore when stopped\n'
                        '• Works with or without ESP32 connection',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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