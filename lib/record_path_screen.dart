 import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'saved_paths_screen.dart';
import 'ws_connection.dart';

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
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
  final WsConnection connection;

  const RecordPathScreen({super.key, required this.connection});

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

  // ✅ DATA time base
  int _recordStartEspMs = 0; // ESP millis at first received DATA
  int _recordStartPhoneMs = 0; // phone ms at first received DATA
  bool _hasStartSync = false;

  // ✅ Fix turns counting (count transitions, not every sample)
  String _prevActForTurns = 'STOP';
  bool _isTurnAction(String a) =>
      a == 'LEFT' || a == 'RIGHT' || a == 'SLIGHT_LEFT' || a == 'SLIGHT_RIGHT';

  // ✅ Prevent duplicate DATA points (espTs monotonic)
  int _lastEspTsRecorded = 0;

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // ✅ Helper: parse key=value fields from DATA string
  Map<String, String> _parseFields(String body) {
    // body example: ts=12345;act=FORWARD;spd=150;s=1,2,3,4,5
    final out = <String, String>{};
    final parts = body.split(';');
    for (final p in parts) {
      final eq = p.indexOf('=');
      if (eq <= 0) continue;
      final k = p.substring(0, eq).trim();
      final v = p.substring(eq + 1).trim();
      if (k.isNotEmpty) out[k] = v;
    }
    return out;
  }

  // ✅ Convert ESP millis to DateTime using start-sync (best)
  DateTime _espMillisToDateTime(int espMs) {
    // first DATA defines mapping between espMs and phone time
    if (!_hasStartSync || _recordStartEspMs == 0 || _recordStartPhoneMs == 0) {
      // fallback: now
      return DateTime.now();
    }
    final delta = espMs - _recordStartEspMs;
    return DateTime.fromMillisecondsSinceEpoch(_recordStartPhoneMs + delta);
  }

  Future<void> _startRecording() async {
    print('▶ Starting recording...');

    // ✅ cancel any previous listener (important!)
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;

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

      // ✅ reset sync
      _recordStartEspMs = 0;
      _recordStartPhoneMs = 0;
      _hasStartSync = false;

      // ✅ reset turns + duplicate protection
      _prevActForTurns = 'STOP';
      _lastEspTsRecorded = 0;
    });

    try {
      widget.connection.send('record_start');
      widget.connection.send('get_status'); // ✅ get first data fast
      print('📤 Command sent: record_start + get_status');

      setState(() {
        _currentStatus = 'Recording started – waiting for DATA...';
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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingTimeSeconds++;
      });
    });

    // ✅ Listen to WebSocket messages
    _webSocketSubscription = widget.connection.stream.listen((message) {
      final msg = message.toString();

      if (!_isRecording) return;

      // ✅ 1) Prefer DATA for recording (best sync)
      if (msg.startsWith("DATA:")) {
        final body = msg.substring(5).trim();
        final fields = _parseFields(body);

        final espTs = int.tryParse(fields['ts'] ?? '') ?? 0;
        final act = (fields['act'] ?? 'STOP').trim();
        final spd = int.tryParse(fields['spd'] ?? '') ?? _currentSpeed;

        // ✅ Reject duplicate/out-of-order DATA (prevents spam)
        if (espTs > 0 && espTs <= _lastEspTsRecorded) {
          return;
        }
        if (espTs > 0) {
          _lastEspTsRecorded = espTs;
        }

        List<int> sensors = [0, 0, 0, 0, 0];
        final sRaw = fields['s'] ?? '';
        final sParts = sRaw.split(',');
        if (sParts.length >= 5) {
          sensors = sParts
              .take(5)
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .toList();
        }

        // ✅ Start sync on first DATA
        if (!_hasStartSync && espTs > 0) {
          _hasStartSync = true;
          _recordStartEspMs = espTs;
          _recordStartPhoneMs = DateTime.now().millisecondsSinceEpoch;
          print(
              "✅ DATA sync start | esp=$_recordStartEspMs | phone=$_recordStartPhoneMs");
        }

        final ts = (espTs > 0) ? _espMillisToDateTime(espTs) : DateTime.now();

        // update last known action/speed for UI reference
        _lastAction = act;
        _currentSpeed = spd;

        // ✅ turns: count transition into a turn (not every sample)
        final wasTurn = _isTurnAction(_prevActForTurns);
        final isTurn = _isTurnAction(act);
        if (!wasTurn && isTurn) {
          _numberOfTurns++;
        }
        _prevActForTurns = act;

        // ✅ Add point (from DATA only)
        recordedPath.add(PathPoint(
          timestamp: ts,
          speed: spd,
          action: act,
          sensorValues: sensors,
        ));

        _totalSpeedSum += spd;
        _speedReadings++;

        if (!mounted) return;
        setState(() {
          _averageSpeed = _speedReadings > 0
              ? (_totalSpeedSum / _speedReadings) / 255 * 100
              : 0.0;

          _currentStatus = "Recording (${recordedPath.length} points)";
        });

        return;
      }

      // ✅ 2) Keep old messages for compatibility (do not record points from SENSORS now)
      if (msg.startsWith("ACTION:")) {
        _lastAction = msg.substring(7).trim();
        return;
      }

      if (msg.startsWith("SPEED:")) {
        _currentSpeed = int.tryParse(msg.substring(6).trim()) ?? _currentSpeed;
        return;
      }

      if (msg.startsWith("MODE:")) {
        // optional
        return;
      }

      if (msg.contains("CONNECTED:ESP32_READY")) {
        // optional
        return;
      }

      // ❌ Do NOT record from SENSORS anymore (DATA replaced it)
    }, onError: (e) {
      print("❌ WS listen error: $e");
    }, onDone: () {
      print("⚠ WS stream done");
    });
  }

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

    // 1) Send stop commands
    try {
      widget.connection.send('record_stop');
      await Future.delayed(const Duration(milliseconds: 100));
      widget.connection.send('stop');
      print('📤 Sent stop commands');
    } catch (e) {
      print('⚠ Failed to send stop commands: $e');
    }

    // 2) Stop timer
    _timer?.cancel();

    setState(() {
      _currentStatus = 'Waiting for remaining data...';
    });

    // 3) Wait to flush last DATA messages
    await Future.delayed(const Duration(milliseconds: 1200));

    // 4) Cancel subscription
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;

    setState(() {
      _isRecording = false;
      _currentStatus = 'Finalizing data...';
    });

    // 5) Fallback point if empty
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

    // 6) Final stats
    setState(() {
      if (_speedReadings > 0) {
        _averageSpeed = (_totalSpeedSum / _speedReadings) / 255 * 100;
      }
      _currentStatus = 'Saving path...';
    });

    // 7) Save to Firestore
    bool success = await _savePathToFirestore();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Path saved successfully! (${recordedPath.length} points)'),
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

  void _navigateToSavedPaths() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedPathsScreen(connection: widget.connection),
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
        title: const Text('Record Path',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRecording
                    ? secondaryColor.withOpacity(0.1)
                    : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isRecording ? secondaryColor : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRecording
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
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
                        Text(_currentStatus,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        if (_isRecording && recordedPath.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Points: ${recordedPath.length} | Speed: $_currentSpeed | Action: $_lastAction',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [primaryColor, secondaryColor]),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _isRecording ? tertiaryColor : primaryColor,
                    width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? secondaryColor.withOpacity(0.5)
                        : Colors.transparent,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isRecording ? Icons.radio_button_checked : Icons.route,
                      size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'LIVE' : 'READY',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text('$_recordingTimeSeconds s',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16)),
                    if (recordedPath.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${recordedPath.length} points',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : _startRecording,
                    icon: const Icon(Icons.fiber_manual_record, size: 24),
                    label: const Text('START RECORDING',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.grey.shade800
                          : secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : null,
                    icon: const Icon(Icons.stop, size: 24),
                    label: const Text('STOP & SAVE',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? tertiaryColor
                          : Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.18),
                    primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: primaryColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Paths Library',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All recorded paths are securely stored in Firestore',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              _firestore.collection('recorded_paths').snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return Text(
                              'Total saved paths: $count',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _navigateToSavedPaths,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'VIEW',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text('RECORDING STATISTICS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _StatisticCard(
                icon: Icons.turn_right,
                label: 'Number of Turns',
                value: _numberOfTurns.toString(),
                color: primaryColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _StatisticCard(
                icon: Icons.timer,
                label: 'Recording Time',
                value: _formatTime(_recordingTimeSeconds),
                color: secondaryColor.withOpacity(0.7)),
            const SizedBox(height: 16),
            _StatisticCard(
                icon: Icons.speed,
                label: 'Average Speed',
                value: '${_averageSpeed.round()}%',
                color: tertiaryColor.withOpacity(0.7)),
            if (recordedPath.isNotEmpty) ...[
              const SizedBox(height: 16),
              _StatisticCard(
                  icon: Icons.analytics,
                  label: 'Total Points',
                  value: recordedPath.length.toString(),
                  color: Colors.purple.withOpacity(0.7)),
            ],
            const SizedBox(height: 40),

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
                      Text('Recording Info',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording
                        ? '• Recording in progress - ${recordedPath.length} points captured\n'
                            '• DATA messages are used for accurate timing\n'
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