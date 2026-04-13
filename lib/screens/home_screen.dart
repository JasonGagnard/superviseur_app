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
  
  final List<String> _allEsps = [
    "192.168.1.50", 
    "192.168.1.51", 
    "192.168.1.52",
    "192.168.1.53"
  ];
  
  final TextEditingController _nameController = TextEditingController();
  String get _storageKey => 'rooms_${widget.userEmail}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_storageKey, json.encode(_rooms.map((r) => r.toMap()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = json.decode(data);
      setState(() {
        _rooms = decoded.map((i) => Room.fromMap(i)).toList();
      });
    }
  }

  void _showMsg(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating)
    );
  }

  // --- GESTION DE LA SUPPRESSION ---
  void _confirmDelete(int index) {
    String roomName = _rooms[index].name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer la pièce ?"),
        content: Text("Voulez-vous vraiment supprimer '$roomName' ?\nL'ESP et le nom redeviendront disponibles."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _rooms.removeAt(index);
                _saveData();
              });
              Navigator.pop(context);
              _showMsg("Pièce '$roomName' supprimée", Colors.blueGrey);
            },
            child: const Text("OUI, SUPPRIMER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- GESTION DE LA CRÉATION ---
  void _showAddRoom() {
    _nameController.clear();
    String? selEsp;
    Color selColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            
            // Calcul des IPs libres
            List<String> remainingEsps = _allEsps
                .where((ip) => !_rooms.any((room) => room.espIp == ip))
                .toList();

            return AlertDialog(
              title: const Text("Nouvelle Pièce"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nom de la pièce",
                        hintText: "ex: Cuisine, Chambre...",
                      ),
                    ),
                    const SizedBox(height: 25),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Assigner un ESP32"),
                      hint: const Text("Choisir une IP"),
                      value: selEsp,
                      items: remainingEsps.isEmpty 
                        ? [const DropdownMenuItem(value: null, child: Text("Plus d'ESP disponible", style: TextStyle(color: Colors.red)))]
                        : remainingEsps.map((ip) => DropdownMenuItem(value: ip, child: Text(ip))).toList(),
                      onChanged: (val) => setPopupState(() => selEsp = val),
                    ),
                    const SizedBox(height: 25),
                    const Align(alignment: Alignment.centerLeft, child: Text("Couleur d'identification :")),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Colors.blue, Colors.red, Colors.green, 
                        Colors.orange, Colors.purple, Colors.teal
                      ].map((color) => GestureDetector(
                        onTap: () => setPopupState(() => selColor = color),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: selColor == color 
                            ? const Icon(Icons.check, size: 18, color: Colors.white) 
                            : null,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                ElevatedButton(
                  onPressed: () {
                    String name = _nameController.text.trim();
                    if (name.isEmpty) {
                      _showMsg("Le nom ne peut pas être vide", Colors.orange);
                      return;
                    }
                    if (_rooms.any((r) => r.name.toLowerCase() == name.toLowerCase())) {
                      _showMsg("Ce nom est déjà utilisé", Colors.redAccent);
                      return;
                    }
                    if (selEsp == null) {
                      _showMsg("Veuillez sélectionner un ESP", Colors.orange);
                      return;
                    }

                    setState(() {
                      _rooms.add(Room(
                        name: name, 
                        espIp: selEsp!, 
                        color: selColor,
                        temperature: 20.0,
                        lastKnownTemperature: 20.0,
                        isOccupied: false,
                        showTemperature: true,
                        showPresence: true,
                        isFroidAlerte: false, // Valeur par défaut
                      ));
                      _saveData();
                    });
                    
                    Navigator.pop(context);
                    _showMsg("Pièce '$name' ajoutée", Colors.green);
                  }, 
                  child: const Text("CRÉER")
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SACHA - ${widget.userEmail}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))
          ),
        ],
      ),
      body: _rooms.isEmpty 
          ? const Center(child: Text("Votre tableau de bord est vide.\nAjoutez votre première pièce !", textAlign: TextAlign.center)) 
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 1.4, // <-- Ratio modifié pour laisser la carte respirer
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12
              ),
              itemCount: _rooms.length,
              itemBuilder: (c, i) => RoomCard(
                room: _rooms[i],
                onDelete: () => _confirmDelete(i), // <-- Fait le lien avec la fonction de suppression
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoom, 
        label: const Text("Ajouter une pièce"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}