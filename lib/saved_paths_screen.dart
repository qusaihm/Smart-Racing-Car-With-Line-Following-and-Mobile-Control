 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'path_details_screen.dart';
import 'ws_connection.dart';

class SavedPathsScreen extends StatefulWidget {
  final WsConnection connection;

  const SavedPathsScreen({super.key, required this.connection});

  @override
  State<SavedPathsScreen> createState() => _SavedPathsScreenState();
}

class _SavedPathsScreenState extends State<SavedPathsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Saved Paths"),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('recorded_paths')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: secondaryColor),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No saved paths yet',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final path = docs[index].data() as Map<String, dynamic>;

              String createdAt = path['createdAt'] ?? "";
              int totalPoints = path['totalPoints'] ?? 0;
              int duration = path['duration'] ?? 0;
              int averageSpeed = path['averageSpeed'] ?? 0;
              int numberOfTurns = path['numberOfTurns'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  title: Text(
                    "Path ${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "📅 $createdAt\n"
                      "📍 Points: $totalPoints\n"
                      "⏱ Duration: ${duration}s\n"
                      "⚡ Avg Speed: $averageSpeed%\n"
                      "↪ Turns: $numberOfTurns",
                      style: const TextStyle(
                          color: Colors.white70, height: 1.4),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PathDetailsScreen(
                          pathData: path,
                          pathId: docs[index].id, // doc id (important)
                          connection: widget.connection,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}