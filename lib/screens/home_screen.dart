import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Liste locale des pièces
  final List<Room> _rooms = [];
  final List<String> _availableEsps = ["192.168.1.50", "192.168.1.51", "192.168.1.52"];
  
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEsp;
  Color _selectedColor = Colors.blue;

  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
  ];

  // --- LA FAMEUSE FONCTION QUI MANQUAIT ---
  void _showAddRoomDialog() {
    _nameController.clear();
    _selectedEsp = null;
    _selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              title: const Text("Ajouter une pièce"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nom (ex: Salon)"),
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Sélectionner l'ESP32"),
                      value: _selectedEsp,
                      items: _availableEsps.map((ip) => DropdownMenuItem(value: ip, child: Text(ip))).toList(),
                      onChanged: (val) => setPopupState(() => _selectedEsp = val),
                    ),
                    const SizedBox(height: 20),
                    const Align(alignment: Alignment.centerLeft, child: Text("Couleur :")),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _colors.map((color) => GestureDetector(
                        onTap: () => setPopupState(() => _selectedColor = color),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 14,
                          child: _selectedColor == color ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                ElevatedButton(onPressed: () => _validate(), child: const Text("Créer")),
              ],
            );
          },
        );
      },
    );
  }

  void _validate() {
    String name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError("Veuillez donner un nom à la pièce", Colors.orange);
      return;
    }

    if (_selectedEsp == null) {
      _showError("Sélectionnez un ESP", Colors.redAccent);
      return;
    }

    if (_rooms.any((r) => r.name.toLowerCase() == name.toLowerCase())) {
      _showError("Ce nom est déjà utilisé !", Colors.redAccent);
      return;
    }

    setState(() {
      _rooms.add(Room(
        name: name,
        espIp: _selectedEsp!,
        color: _selectedColor,
        temperature: 21.5,
        lastKnownTemperature: 21.5,
        isOccupied: false,
      ));
      _availableEsps.remove(_selectedEsp);
    });
    
    Navigator.pop(context);
    _showError("Pièce '$name' ajoutée", Colors.green);
  }

  void _showError(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SACHA"), 
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _rooms.isEmpty
          ? const Center(child: Text("Aucune pièce. Ajoutez-en une !"))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 1.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _rooms.length,
              itemBuilder: (context, index) => RoomCard(room: _rooms[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoomDialog, // <-- ICI, LE BOUTON EST RÉACTIVÉ
        label: const Text("Ajouter"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}