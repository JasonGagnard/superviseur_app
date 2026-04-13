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
  final List<Room> _rooms = [];
  final List<String> _availableEsps = ["192.168.1.50", "192.168.1.51", "192.168.1.52"];
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEsp;
  Color _selectedColor = Colors.blue;

  void _validate() {
    String name = _nameController.text.trim();
    if (name.isEmpty || _selectedEsp == null) return;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SACHA"),
        elevation: 1,
        actions: [
          // L'ÉCROU POUR LES PARAMÈTRES
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _rooms.isEmpty
          ? const Center(child: Text("Aucune pièce ajoutée"))
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
        onPressed: () => /* Ta fonction de dialog */ null, 
        label: const Text("Ajouter"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}