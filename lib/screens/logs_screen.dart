import 'package:flutter/material.dart';

// --- MODÈLE DE DONNÉES POUR LES LOGS ---
enum LogType { user, system }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry({required this.timestamp, required this.message, required this.type});
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

  // --- FAUSSES DONNÉES (Pour tester le design) ---
  // Remplace ceci plus tard par la lecture de tes vrais logs via SharedPreferences
  final List<LogEntry> _allLogs = [
    LogEntry(timestamp: DateTime.now().subtract(const Duration(minutes: 5)), message: "Scénario 'Nuit' activé", type: LogType.user),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(minutes: 6)), message: "Connexion ESP32 (10.105.139.24) rétablie", type: LogType.system),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(minutes: 45)), message: "Présence détectée dans le Salon", type: LogType.user),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(minutes: 60)), message: "Perte de signal caméra (Cuisine)", type: LogType.system),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(hours: 2)), message: "Température 'Chambre' modifiée à 19°C", type: LogType.user),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(hours: 3)), message: "Redémarrage de l'application SACHA", type: LogType.system),
    LogEntry(timestamp: DateTime.now().subtract(const Duration(hours: 5)), message: "Pièce 'Salle de bain' ajoutée au plan", type: LogType.user),
  ];

  @override
  Widget build(BuildContext context) {
    // On filtre la liste en fonction du bouton sélectionné
    List<LogEntry> filteredLogs = _allLogs.where((log) => log.type == _selectedType).toList();

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
                          onTap: () => setState(() => _selectedType = LogType.user),
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
                          onTap: () => setState(() => _selectedType = LogType.system),
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
            child: filteredLogs.isEmpty
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