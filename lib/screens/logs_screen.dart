import 'package:flutter/material.dart';
import '../services/backend_api.dart';

// --- MODÈLE DE DONNÉES POUR LES LOGS ---
enum LogType { user, system }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry({required this.timestamp, required this.message, required this.type});

  factory LogEntry.fromApi(Map<String, dynamic> map) {
    final rawType = map['log_type']?.toString() ?? 'system';
    final parsedType = rawType == 'user' ? LogType.user : LogType.system;
    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '');

    return LogEntry(
      timestamp: createdAt ?? DateTime.now(),
      message: map['action_log']?.toString() ?? '',
      type: parsedType,
    );
  }
}

class LogsScreen extends StatefulWidget {
  final String userEmail;
  const LogsScreen({super.key, required this.userEmail});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // Le type actuellement sélectionné par le switch (Par défaut: Utilisateur)
  LogType _selectedType = LogType.user;

  bool _isLoading = true;
  List<LogEntry> _allLogs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final logType = _selectedType == LogType.user ? 'user' : 'system';
      final response = await BackendApi.instance.listLogs(
        username: widget.userEmail,
        logType: logType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allLogs = response.map(LogEntry.fromApi).toList();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _allLogs = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le backend renvoie deja le type filtre.
    List<LogEntry> filteredLogs = _allLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Journal des événements"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. LE SWITCH PREMIUM (Utilisateur / Système)
          // ==========================================
          Container(
            color: Colors.blueGrey,
            padding: const EdgeInsets.only(bottom: 20, top: 10, left: 20, right: 20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                children: [
                  // L'animation du fond (la pilule blanche qui glisse)
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: _selectedType == LogType.user ? Alignment.centerLeft : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Les textes par-dessus
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedType = LogType.user);
                            _loadLogs();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _selectedType == LogType.user ? Colors.blueGrey : Colors.white70,
                              ),
                              child: const Text("Utilisateur"),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedType = LogType.system);
                            _loadLogs();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _selectedType == LogType.system ? Colors.blueGrey : Colors.white70,
                              ),
                              child: const Text("Système"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. LA LISTE DES LOGS FILTRÉS
          // ==========================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLogs.isEmpty
                ? const Center(
                    child: Text("Aucun événement dans cette catégorie.", style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final bool isUser = log.type == LogType.user;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUser ? Icons.person : Icons.memory,
                              color: isUser ? Colors.blue : Colors.orange,
                            ),
                          ),
                          title: Text(
                            log.message,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              // Police légèrement différente (monospace) pour le système
                              fontFamily: isUser ? null : 'Courier',
                              fontSize: isUser ? 15 : 13,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _formatTime(log.timestamp),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- FORMATAGE DE L'HEURE ---
  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    return "Aujourd'hui à $h:$m";
  }
}