import 'package:flutter/material.dart';
import 'logs_screen.dart'; // Import pour la page des logs
import 'login_screen.dart'; // Import pour la déconnexion
import 'consumption_simulator_screen.dart'; // <-- NOUVEAU : Import du simulateur

class SettingsScreen extends StatefulWidget {
  final String userEmail; 
  
  const SettingsScreen({super.key, required this.userEmail});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Valeurs par défaut
  double _tempPresence = 21.0;
  double _tempAbsence = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration Globale"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      // J'ai passé la Column en ListView pour éviter les problèmes d'écran trop petit
      // maintenant qu'il y a plus de boutons.
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            "Consignes de Température",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          // Slider pour Présence Humaine
          _buildTempSlider(
            title: "En présence humaine",
            subtitle: "Température de confort",
            value: _tempPresence,
            icon: Icons.person,
            color: Colors.orange,
            onChanged: (val) => setState(() => _tempPresence = val),
          ),

          const SizedBox(height: 30),

          // Slider pour Absence
          _buildTempSlider(
            title: "En cas d'absence",
            subtitle: "Mode éco / hors-gel",
            value: _tempAbsence,
            icon: Icons.person_off,
            color: Colors.blue,
            onChanged: (val) => setState(() => _tempAbsence = val),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // --- NOUVEAU : BOUTON SIMULATEUR D'ÉCONOMIES ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9), // Vert très clair
              child: Icon(Icons.bolt, color: Colors.green),
            ),
            title: const Text("Simulateur d'économies", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Estimer l'impact sur la facture"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConsumptionSimulatorScreen()),
              );
            },
          ),
          
          const Divider(),

          // --- BOUTON JOURNAL DES LOGS ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD), // Bleu très clair
              child: Icon(Icons.receipt_long, color: Colors.blue),
            ),
            title: const Text("Journal des événements"),
            subtitle: const Text("Voir l'historique des actions"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogsScreen(userEmail: widget.userEmail)),
              );
            },
          ),
          
          const Divider(),

          // --- BOUTON DÉCONNEXION ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE), // Rouge très clair
              child: Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Retourne à la page de connexion et vide l'historique de navigation
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 40), // Espace avant le bouton enregistrer

          // --- BOUTON ENREGISTRER ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              // Ici on enregistrera les données de température plus tard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Configurations enregistrées"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- TON WIDGET DE SLIDER INTACT ---
  Widget _buildTempSlider({
    required String title,
    required String subtitle,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text("${value.toStringAsFixed(1)}°C", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Slider(
          value: value,
          min: 15.0,
          max: 28.0,
          divisions: 26,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}