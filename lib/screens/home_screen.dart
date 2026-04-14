import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/scenario.dart'; // <-- IMPORTANT : Ajout du modèle Scénario
import '../widgets/room_card.dart';
import 'settings_screen.dart';
import '../utils/logger.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Room> _rooms = [];
  List<Scenario> _scenarios = []; // <-- Nouvelle liste pour les scénarios

  final List<String> _allEsps = ["10.105.139.24"];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cameraUrlController = TextEditingController();

  String get _storageKeyRooms => 'plan_rooms_${widget.userEmail}';
  String get _storageKeyScenarios => 'scenarios_${widget.userEmail}'; // <-- Clé pour les scénarios

  bool _isScenarioPressed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- PERSISTANCE DES DONNÉES ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKeyRooms, json.encode(_rooms.map((r) => r.toMap()).toList()));
    await prefs.setString(_storageKeyScenarios, json.encode(_scenarios.map((s) => s.toMap()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rData = prefs.getString(_storageKeyRooms);
    final String? sData = prefs.getString(_storageKeyScenarios);
    
    setState(() {
      if (rData != null) {
        _rooms = (json.decode(rData) as List).map((item) => Room.fromMap(item)).toList();
      }
      if (sData != null) {
        _scenarios = (json.decode(sData) as List).map((item) => Scenario.fromMap(item)).toList();
      }
    });
  }

  // --- LOGIQUE DE SUPPRESSION DE PIÈCE ---
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

  // --- NOUVEAU DIALOGUE D'AJOUT DE SCÉNARIO ---
  void _showAddScenario() {
    String sName = "";
    List<String> selectedRooms = [];
    double selectedTemp = 21.0;
    
    // Plage horaire par défaut
    TimeOfDay startTime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 7, minute: 0);
    
    IconData selectedIcon = Icons.nights_stay;
    Color selectedColor = Colors.indigo;

    // Grande palette de couleurs variées
    final List<Color> palette = [
      Colors.indigo, Colors.teal, Colors.deepPurple, Colors.pink, 
      Colors.amber, Colors.cyan, Colors.brown, Colors.lightGreen
    ];

    // Icônes thématiques
    final Map<String, IconData> iconsMap = {
      "Lune": Icons.nights_stay,
      "Cadenas": Icons.lock,
      "Soleil": Icons.wb_sunny,
      "Maison": Icons.home,
      "Film": Icons.movie,
      "Éclair": Icons.bolt,
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
          return AlertDialog(
            title: const Text("Créer un Scénario"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Nom du scénario (ex: Nuit, Vacances...)"),
                    onChanged: (val) => sName = val,
                  ),
                  const SizedBox(height: 20),
                  
                  const Text("1. Icône et Couleur", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: iconsMap.values.map((icon) => GestureDetector(
                      onTap: () => setPopupState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon ? selectedColor.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selectedIcon == icon ? selectedColor : Colors.grey),
                        ),
                        child: Icon(icon, color: selectedIcon == icon ? selectedColor : Colors.grey),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: palette.map((c) => GestureDetector(
                      onTap: () => setPopupState(() => selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: c, radius: 14, 
                        child: selectedColor == c ? const Icon(Icons.check, size: 14, color: Colors.white) : null
                      ),
                    )).toList(),
                  ),

                  const Divider(height: 30),
                  
                  const Text("2. Plage d'activation", style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline, color: Colors.green),
                    title: const Text("Heure de début"),
                    trailing: Text(startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: startTime);
                      if (time != null) setPopupState(() => startTime = time);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                    title: const Text("Heure de fin"),
                    trailing: Text(endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: endTime);
                      if (time != null) setPopupState(() => endTime = time);
                    },
                  ),

                  const Divider(height: 30),

                  const Text("3. Action souhaitée", style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: selectedTemp, min: 15, max: 28, divisions: 26,
                    activeColor: selectedColor,
                    onChanged: (v) => setPopupState(() => selectedTemp = v),
                  ),
                  Center(child: Text("${selectedTemp.toStringAsFixed(1)}°C", style: TextStyle(color: selectedColor, fontWeight: FontWeight.bold, fontSize: 18))),
                  
                  const SizedBox(height: 10),
                  const Text("Appliquer sur :", style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._rooms.map((room) => CheckboxListTile(
                    activeColor: selectedColor,
                    title: Text(room.name),
                    value: selectedRooms.contains(room.name),
                    onChanged: (val) {
                      setPopupState(() {
                        val! ? selectedRooms.add(room.name) : selectedRooms.remove(room.name);
                      });
                    },
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: selectedColor, foregroundColor: Colors.white),
                onPressed: () {
                  if (sName.isEmpty) return;
                  setState(() {
                    _scenarios.add(Scenario(
                      name: sName,
                      iconCode: selectedIcon.codePoint,
                      colorValue: selectedColor.value,
                      startHour: startTime.hour,
                      startMinute: startTime.minute,
                      endHour: endTime.hour,
                      endMinute: endTime.minute,
                      roomNames: selectedRooms,
                      targetTemp: selectedTemp,
                    ));
                    _saveData();
                  });
                  AppLogger.log(widget.userEmail, "Scénario '$sName' créé (${startTime.format(context)} à ${endTime.format(context)})");
                  Navigator.pop(context);
                }, 
                child: const Text("SAUVEGARDER")
              ),
            ],
          );
        }
      ),
    );
  }

  // --- DIALOGUE D'AJOUT DE PIÈCE ---
  void _showAddRoom() {
    _nameController.clear();
    _cameraUrlController.clear();
    String? selEsp;
    Color selColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
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
                    initialValue: selEsp,
                    items: remainingEsps.map((ip) => DropdownMenuItem(value: ip, child: Text(ip))).toList(),
                    onChanged: (v) => setPopupState(() => selEsp = v),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _cameraUrlController,
                    decoration: const InputDecoration(labelText: "URL du WebSocket thermique", hintText: "ws://10.105.139.24:81/"),
                  ),
                  const SizedBox(height: 12),
                  const Text("Optionnel: laisse vide si le port 81 est utilisé par défaut.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple].map(
                      (c) => GestureDetector(
                        onTap: () => setPopupState(() => selColor = c),
                        child: CircleAvatar(backgroundColor: c, radius: 15, child: selColor == c ? const Icon(Icons.check, size: 15, color: Colors.white) : null),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isEmpty || selEsp == null) return;
                  final streamUrl = _cameraUrlController.text.trim().isEmpty ? 'ws://$selEsp:81/' : _cameraUrlController.text.trim();
                  setState(() {
                    _rooms.add(Room(name: _nameController.text, espIp: selEsp!, cameraUrl: streamUrl, color: selColor));
                    _saveData();
                  });
                  Navigator.pop(context);
                },
                child: const Text("AJOUTER"),
              ),
            ],
          );
        },
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => SettingsScreen(userEmail: widget.userEmail)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. LE PLAN D'ARCHITECTE (Prend le maximum de place)
          // ==========================================
          Expanded(
            child: _rooms.isEmpty
              ? const Center(child: Text("Plan vide.\nAppuyez sur + pour commencer.", textAlign: TextAlign.center))
              : Stack(
                  children: _rooms.asMap().entries.map((entry) {
                    int index = entry.key;
                    Room room = entry.value;

                    return Positioned(
                      left: room.x,
                      top: room.y,
                      child: GestureDetector(
                        onPanUpdate: (details) => setState(() { room.x += details.delta.dx; room.y += details.delta.dy; }),
                        onPanEnd: (details) => _saveData(),
                        child: SizedBox(
                          width: 240, height: 180,
                          child: RoomCard(room: room, onDelete: () => _confirmDelete(index)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          ),

          // ==========================================
          // 2. LA BARRE DES SCÉNARIOS (En dessous du plan)
          // ==========================================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 15, bottom: 5),
                  child: Text("Mes Scénarios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),
                SizedBox(
                  height: 100, // Hauteur de la zone défilante
                  child: _scenarios.isEmpty
                      ? const Center(child: Text("Aucun scénario configuré", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: _scenarios.length,
                          itemBuilder: (context, index) {
                            final scenario = _scenarios[index];
                            final color = Color(scenario.colorValue);
                            
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: color.withOpacity(0.5), width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconData(scenario.iconCode, fontFamily: 'MaterialIcons'), color: color, size: 28),
                                  const SizedBox(height: 5),
                                  Text(scenario.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          )
        ],
      ),
            
      // --- LA ZONE DES BOUTONS (Customisée) ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // BOUTON PREMIUM "SCÉNARIO"
          GestureDetector(
            onTapDown: (_) => setState(() => _isScenarioPressed = true),
            onTapUp: (_) {
              setState(() => _isScenarioPressed = false);
              _showAddScenario();
            },
            onTapCancel: () => setState(() => _isScenarioPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: _isScenarioPressed
                      ? [const Color(0xFF11998E), const Color(0xFF38EF7D)] 
                      : [const Color(0xFF00C6FF), const Color(0xFF0072FF)], 
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Ajouter Scénario", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // BOUTON CLASSIQUE "AJOUTER PIÈCE"
          FloatingActionButton(
            heroTag: "btnRoom",
            backgroundColor: Colors.blueGrey,
            elevation: 4, 
            onPressed: _showAddRoom,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}