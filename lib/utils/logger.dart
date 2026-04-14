import 'package:shared_preferences/shared_preferences.dart';

class AppLogger {
  // Ajouter un log
  static Future<void> log(String userEmail, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'logs_$userEmail';
    
    // On récupère l'historique existant
    List<String> logs = prefs.getStringList(key) ?? [];
    
    // On crée la date au format lisible (ex: 14:30 - 25/10/2023)
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateString = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}";
    
    // On ajoute le nouveau log AU DÉBUT de la liste
    logs.insert(0, "$timeString ($dateString)|$message");
    
    // On sauvegarde
    await prefs.setStringList(key, logs);
  }

  // Récupérer les logs
  static Future<List<String>> getLogs(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('logs_$userEmail') ?? [];
  }

  // Vider les logs
  static Future<void> clearLogs(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logs_$userEmail');
  }
}