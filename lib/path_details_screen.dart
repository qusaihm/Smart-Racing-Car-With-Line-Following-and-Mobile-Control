import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/src/channel.dart';
import 'theme.dart';

class PathDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> pathData;

  const PathDetailsScreen({super.key, required this.pathData, required String pathId, required WebSocketChannel channel});

  @override
  Widget build(BuildContext context) {
    List<dynamic> points = pathData['pathPoints'] ?? [];
    String id = pathData['id'] ?? "Unknown";
    String createdAt = pathData['createdAt'] ?? "-";
    int duration = pathData['duration'] ?? 0;
    int turns = pathData['numberOfTurns'] ?? 0;
    int avgSpeed = pathData['averageSpeed'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Path Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ------------------ Top Info ------------------
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Path ID:", style: TextStyle(color: Colors.white54)),
                  Text(id, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),

                  Text("Created At:", style: TextStyle(color: Colors.white54)),
                  Text(createdAt, style: TextStyle(color: Colors.white)),
                  SizedBox(height: 12),

                  Text("Duration:", style: TextStyle(color: Colors.white54)),
                  Text("${_formatDuration(duration)}", style: TextStyle(color: Colors.white)),
                  SizedBox(height: 12),

                  Text("Turns:", style: TextStyle(color: Colors.white54)),
                  Text("$turns", style: TextStyle(color: primaryColor)),
                  SizedBox(height: 12),

                  Text("Average Speed:", style: TextStyle(color: Colors.white54)),
                  Text("$avgSpeed%", style: TextStyle(color: tertiaryColor)),
                ],
              ),
            ),

            SizedBox(height: 30),

            // ------------------ Title ------------------
            Text(
              "Recorded Points (${points.length})",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // ------------------ Points List ------------------
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: points.length,
              itemBuilder: (context, index) {
                final point = points[index];
                List sensors = point['sensors'] ?? [0, 0, 0, 0, 0];

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
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
                        style: TextStyle(color: secondaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      _rowInfo("Action", point['action']),
                      _rowInfo("Speed", point['speed'].toString()),
                      _rowInfo("Timestamp", point['timestamp']),

                      SizedBox(height: 12),

                      Text("Sensors:", style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sensorBox("S1", sensors[0]),
                          _sensorBox("S2", sensors[1]),
                          _sensorBox("S3", sensors[2]),
                          _sensorBox("S4", sensors[3]),
                          _sensorBox("S5", sensors[4]),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 30),

            // ------------------ Delete Button ------------------
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _deletePath(context, id),
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text("Delete Path"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
              ),
            ),

            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ------------------ Widgets ------------------

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54)),
          Text(value, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sensorBox(String name, int value) {
    return Container(
      padding: EdgeInsets.all(10),
      width: 55,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ------------------ Delete function ------------------

  Future<void> _deletePath(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection("recorded_paths")
          .doc(id)
          .delete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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

  // ------------------ Duration format ------------------

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}