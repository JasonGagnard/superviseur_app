import 'package:flutter/material.dart';
import '../utils/logger.dart';

class LogsScreen extends StatefulWidget {
  final String userEmail;
  const LogsScreen({super.key, required this.userEmail});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await AppLogger.getLogs(widget.userEmail);
    setState(() => _logs = logs);
  }

  void _clearLogs() async {
    await AppLogger.clearLogs(widget.userEmail);
    _loadLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Historique effacé"), backgroundColor: Colors.blueGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Journal des événements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Vider les logs",
            onPressed: _clearLogs,
          )
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text("Aucun événement enregistré.", style: TextStyle(color: Colors.blueGrey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                // On sépare la date du message (grâce au séparateur '|')
                final parts = _logs[index].split('|');
                final datePart = parts[0];
                final messagePart = parts.length > 1 ? parts[1] : "";

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1E88E5),
                      child: Icon(Icons.history, color: Colors.white, size: 20),
                    ),
                    title: Text(messagePart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(datePart, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}