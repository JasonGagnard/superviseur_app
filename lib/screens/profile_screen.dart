import 'dart:io'; // <-- NOUVEAU
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/backend_api.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final int roomCount;
  final int scenarioCount;

  const ProfileScreen({
    super.key, 
    required this.username,
    required this.roomCount,
    required this.scenarioCount,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variables locales pour stocker les infos chargées
  String _userEmail = "";
  String _displayName = ""; // Prénom + NOM
  String? _profileImagePath; // Chemin de la photo

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userData = await BackendApi.instance.getUser(widget.username);

      final String firstName = userData['first_name']?.toString() ?? "";
      final String lastName = userData['last_name']?.toString() ?? "";

      if (!mounted) {
        return;
      }

      setState(() {
        _userEmail = userData['email']?.toString() ?? "Email non renseigné";
        _displayName = "$firstName $lastName".trim();
        _profileImagePath = userData['profile_image_path']?.toString();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _userEmail = "Utilisateur inconnu";
        _displayName = widget.username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- EN-TÊTE DU PROFIL ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, top: 20),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // ==========================================
                // L'ESPACE PHOTO CIRCULAIRE D'AFFICHAGE
                // ==========================================
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  // Si un chemin d'image existe et est valide, on l'affiche
                  backgroundImage: (_profileImagePath != null && File(_profileImagePath!).existsSync()) 
                      ? FileImage(File(_profileImagePath!)) 
                      : null,
                  // Sinon, on affiche l'icône par défaut
                  child: (_profileImagePath == null || !File(_profileImagePath!).existsSync())
                      ? const Icon(Icons.account_circle, size: 100, color: Colors.blueGrey)
                      : null,
                ),
                
                const SizedBox(height: 15),
                
                // --- AFFICHAGE : NOM ET PRÉNOM ---
                Text(
                  _displayName.isNotEmpty ? _displayName : widget.username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 5),
                
                // Sous-titre : Email
                Text(
                  _userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- STATISTIQUES DE LA MAISON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.meeting_room,
                    title: "Pièces",
                    value: widget.roomCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.bolt,
                    title: "Scénarios",
                    value: widget.scenarioCount.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- ACTIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    title: const Text("Modifier le profil"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fonctionnalité à venir !")),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}