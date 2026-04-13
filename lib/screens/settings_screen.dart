import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            const SizedBox(height: 40),

            // Slider pour Absence
            _buildTempSlider(
              title: "En cas d'absence",
              subtitle: "Mode éco / hors-gel",
              value: _tempAbsence,
              icon: Icons.person_off,
              color: Colors.blue,
              onChanged: (val) => setState(() => _tempAbsence = val),
            ),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: Colors.blueGrey,
              ),
              onPressed: () {
                // Ici on enregistrera les données plus tard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Configurations enregistrées")),
                );
                Navigator.pop(context);
              },
              child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

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