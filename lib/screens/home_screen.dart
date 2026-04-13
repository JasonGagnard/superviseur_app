import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Room> _rooms = [];
  
  // Liste des IPs de tes ESP32 disponibles
  final List<String> _allEsps = [
    "192.168.1.50", 
    "192.168.1.51", 
    "192.168.1.52",
    "192.168.1.53"
  ];
  
  final TextEditingController _nameController = TextEditingController();
  
  // Clé de stockage unique par utilisateur
  String get _storageKey => 'plan_rooms_${widget.userEmail}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- PERSISTANCE DES DONNÉES ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(_rooms.map((r) => r.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = json.decode(data);
      setState(() {
        _rooms = decoded.map((item) => Room.fromMap(item)).toList();
      });
    }
  }

  // --- LOGIQUE DE SUPPRESSION ---
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Supprimer la pièce ?"),
        content: Text("Voulez-vous retirer '${_rooms[index].name}' du plan ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("ANNULER")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _rooms.removeAt(index);
                _saveData();
              });
              Navigator.pop(c);
            },
            child: const Text("OUI, SUPPRIMER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- DIALOGUE D'AJOUT (AVEC FILTRAGE ESP) ---
  void _showAddRoom() {
    _nameController.clear();
    String? selEsp;
    Color selColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
          // On ne montre que les IPs pas encore utilisées
          List<String> remainingEsps = _allEsps
              .where((ip) => !_rooms.any((room) => room.espIp == ip))
              .toList();

          return AlertDialog(
            title: const Text("Nouvelle pièce sur le plan"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nom")),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Assigner ESP32"),
                    value: selEsp,
                    items: remainingEsps.map((ip) => DropdownMenuItem(value: ip, child: Text(ip))).toList(),
                    onChanged: (v) => setPopupState(() => selEsp = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple].map((c) => 
                      GestureDetector(
                        onTap: () => setPopupState(() => selColor = c),
                        child: CircleAvatar(backgroundColor: c, radius: 15, child: selColor == c ? const Icon(Icons.check, size: 15, color: Colors.white) : null),
                      )
                    ).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isEmpty || selEsp == null) return;
                  setState(() {
                    _rooms.add(Room(name: _nameController.text, espIp: selEsp!, color: selColor));
                    _saveData();
                  });
                  Navigator.pop(context);
                }, 
                child: const Text("AJOUTER")
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text("SACHA - Plan de ${widget.userEmail}"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))),
        ],
      ),
      body: _rooms.isEmpty 
          ? const Center(child: Text("Plan vide.\nAppuyez sur + pour commencer.", textAlign: TextAlign.center)) 
          : Stack(
              children: _rooms.asMap().entries.map((entry) {
                int index = entry.key;
                Room room = entry.value;

                return Positioned(
                  left: room.x,
                  top: room.y,
                  child: GestureDetector(
                    // Logique de Drag & Drop
                    onPanUpdate: (details) {
                      setState(() {
                        room.x += details.delta.dx;
                        room.y += details.delta.dy;
                      });
                    },
                    onPanEnd: (details) => _saveData(), // Sauvegarde après déplacement
                    child: SizedBox(
                      width: 240, // Largeur fixe pour le bloc plan
                      height: 180, // Hauteur fixe pour le bloc plan
                      child: RoomCard(
                        room: room,
                        onDelete: () => _confirmDelete(index),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoom,
        child: const Icon(Icons.add),
      ),
    );
  }
}