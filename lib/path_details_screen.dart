 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'ws_connection.dart';
import 'path_plot.dart'; // الرسم

class PathDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> pathData;
  final String pathId; // Firestore document ID
  final WsConnection connection; // kept for consistency (future use)

  const PathDetailsScreen({
    super.key,
    required this.pathData,
    required this.pathId,
    required this.connection,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> pointsAny = pathData['pathPoints'] ?? [];
    final String idInsideData = pathData['id'] ?? "Unknown";
    final String createdAt = pathData['createdAt'] ?? "-";
    final int duration = pathData['duration'] ?? 0;
    final int turns = pathData['numberOfTurns'] ?? 0;
    final int avgSpeed = pathData['averageSpeed'] ?? 0;

    // ✅ Convert points safely (works with Firestore maps)
    final List<Map<String, dynamic>> safePoints = [];
    for (final p in pointsAny) {
      try {
        if (p is Map) {
          safePoints.add(Map<String, dynamic>.from(p));
        }
      } catch (_) {
        // ignore invalid point
      }
    }

    // ✅ Build plot points (dead-reckoning)
    final plotPts = safePoints.isNotEmpty
    ? PathReconstructor.reconstructFromSensors(
        pathPoints: safePoints,
        threshold: 2000,
        speedScale: 0.0028,
        kTurn: 1.25,        // زيدها إذا لساتها ما بتلف كفاية
        maxTurnRate: 3.0,   // زيدها إذا بدك منعطفات أقوى
      )
    : <PlotPoint>[const PlotPoint(0, 0)];


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Path Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Top Info ------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Doc ID (Firestore):",
                      style: TextStyle(color: Colors.white54)),
                  Text(pathId,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  const Text("Path ID (Saved in Data):",
                      style: TextStyle(color: Colors.white54)),
                  Text(idInsideData, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),

                  const Text("Created At:",
                      style: TextStyle(color: Colors.white54)),
                  Text(createdAt, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),

                  const Text("Duration:",
                      style: TextStyle(color: Colors.white54)),
                  Text(_formatDuration(duration),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),

                  const Text("Turns:",
                      style: TextStyle(color: Colors.white54)),
                  Text("$turns", style: const TextStyle(color: primaryColor)),
                  const SizedBox(height: 12),

                  const Text("Average Speed:",
                      style: TextStyle(color: Colors.white54)),
                  Text("$avgSpeed%", style: const TextStyle(color: tertiaryColor)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ------------------ Path Plot ------------------
            const Text(
              "Path Preview",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (plotPts.length < 2)
                    ? const Center(
                        child: Text(
                          "Not enough data to draw path",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : PathPlot(
                        points: plotPts,
                        lineColor: secondaryColor,
                        strokeWidth: 3,
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // ------------------ Title ------------------
            Text(
              "Recorded Points (${safePoints.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ------------------ Points List ------------------
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: safePoints.length,
              itemBuilder: (context, index) {
                final point = safePoints[index];
                final List sensors = point['sensors'] ?? [0, 0, 0, 0, 0];

                int sensorAt(int i) {
                  final v = (i < sensors.length) ? sensors[i] : 0;
                  if (v is num) return v.toInt();
                  return int.tryParse(v.toString()) ?? 0;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Point ${index + 1}",
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _rowInfo("Action", (point['action'] ?? "-").toString()),
                      _rowInfo("Speed", (point['speed'] ?? 0).toString()),
                      _rowInfo("Timestamp", (point['timestamp'] ?? "-").toString()),

                      const SizedBox(height: 12),

                      const Text("Sensors:",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sensorBox("S1", sensorAt(0)),
                          _sensorBox("S2", sensorAt(1)),
                          _sensorBox("S3", sensorAt(2)),
                          _sensorBox("S4", sensorAt(3)),
                          _sensorBox("S5", sensorAt(4)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // ------------------ Delete Button ------------------
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete Path"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorBox(String name, int value) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: 55,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          "Delete Path?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this path? This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePath(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePath(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection("recorded_paths").doc(pathId).delete();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Path deleted successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error deleting path: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
