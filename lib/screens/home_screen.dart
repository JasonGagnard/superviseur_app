import 'profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/scenario.dart';
import '../widgets/room_card.dart';
import 'settings_screen.dart';
import '../utils/logger.dart';
import '../services/backend_api.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Room> _rooms = [];
  List<Scenario> _scenarios = [];
  bool _isLoadingData = true;

  final List<String> _discoveredEsps = [];
  final List<String> _knownEspCandidates = ['10.105.139.24'];
  bool _isScanningEsp32 = false;
  String? _networkStatusMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cameraUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      _refreshEsp32Discovery(showSnackBar: false);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final roomsData = await BackendApi.instance.listEspNodes(widget.userEmail);
      final scenariosData = await BackendApi.instance.listScenarios(widget.userEmail);

      if (!mounted) {
        return;
      }

      setState(() {
        _rooms = roomsData.map(Room.fromApi).toList();
        _scenarios = scenariosData.map(Scenario.fromApi).toList();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      print('ERROR LOADING DATA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur backend: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _persistRoomPosition(Room room) async {
    if (room.id == null) {
      return;
    }

    try {
      await BackendApi.instance.updateEspNode(room.id!, {
        'pos_x': room.x,
        'pos_y': room.y,
      });
    } catch (_) {
      // Ignore sync error here to keep drag interaction smooth.
    }
  }

  List<String> get _availableEspHosts {
    return List<String>.from(_discoveredEsps);
  }

  Future<void> _refreshEsp32Discovery({bool showSnackBar = true}) async {
    if (_isScanningEsp32) {
      return;
    }

    setState(() {
      _isScanningEsp32 = true;
      _networkStatusMessage = 'Analyse du Wi-Fi en cours...';
    });

    List<String> discoveredHosts = const [];
    try {
      final scanResponse = await BackendApi.instance.scanEsp32OnBackend(
        preferredHosts: _availableEspHosts,
        extraCandidates: _knownEspCandidates,
        timeoutMs: 1500,
        maxResults: 10,
        scanFullSubnet: true,
      );

      discoveredHosts = (scanResponse['discovered_hosts'] as List<dynamic>? ?? const [])
          .map((host) => host.toString())
          .where((host) => host.trim().isNotEmpty)
          .toList();
    } catch (_) {
      discoveredHosts = const [];
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isScanningEsp32 = false;
      if (discoveredHosts.isNotEmpty) {
        _discoveredEsps
          ..clear()
          ..addAll(discoveredHosts);
        if (discoveredHosts.length == 1) {
          _networkStatusMessage = 'ESP32 détecté sur ${discoveredHosts.first}';
        } else {
          _networkStatusMessage = '${discoveredHosts.length} ESP32 détectés (${discoveredHosts.join(', ')})';
        }
      } else {
        _discoveredEsps.clear();
        _networkStatusMessage = 'Aucun ESP32 détecté sur le réseau actuel';
      }
    });

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_networkStatusMessage ?? 'Analyse terminée')),
      );
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Supprimer la pièce ?"),
        content: Text("Voulez-vous retirer '${_rooms[index].name}' du plan ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final room = _rooms[index];
              if (room.id != null) {
                try {
                  await BackendApi.instance.deleteEspNode(room.id!);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                  return;
                }
              }

              if (!mounted) {
                return;
              }

              setState(() {
                _rooms.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text(
              "OUI, SUPPRIMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE D'ACTIVATION ET RÉSOLUTION DE CONFLITS ---
  Future<void> _toggleScenario(int index) async {
    final selected = _scenarios[index];
    if (selected.id == null) {
      return;
    }

    final targetState = !selected.isActive;

    try {
      if (targetState) {
        final selectedRooms = selected.roomNames;
        for (var i = 0; i < _scenarios.length; i++) {
          if (i == index) {
            continue;
          }

          final current = _scenarios[i];
          final hasConflict = current.isActive &&
              current.roomNames.any((room) => selectedRooms.contains(room));

          if (hasConflict && current.id != null) {
            await BackendApi.instance.updateScenario(current.id!, {
              'is_active': false,
            });
            AppLogger.log(
              widget.userEmail,
              "Conflit : Scénario '${current.name}' désactivé.",
            );
          }
        }
      }

      await BackendApi.instance.updateScenario(selected.id!, {
        'is_active': targetState,
      });

      AppLogger.log(
        widget.userEmail,
        "Scénario '${selected.name}' ${targetState ? 'activé' : 'désactivé'}.",
      );

      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // --- DIALOGUE UNIFIÉ : CRÉATION ET ÉDITION DE SCÉNARIO ---
  void _showScenarioForm([int? index]) {
    final bool isEditing = index != null;
    final Scenario? currentScenario = isEditing ? _scenarios[index] : null;

    String sName = currentScenario?.name ?? "";
    List<String> selectedRooms = currentScenario != null
        ? List<String>.from(currentScenario.roomNames)
        : [];
    double selectedTemp = currentScenario?.targetTemp ?? 21.0;
    bool useTimeLimit = currentScenario?.useTimeLimit ?? true;

    TimeOfDay startTime = currentScenario != null
        ? TimeOfDay(
            hour: currentScenario.startHour,
            minute: currentScenario.startMinute,
          )
        : const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay endTime = currentScenario != null
        ? TimeOfDay(
            hour: currentScenario.endHour,
            minute: currentScenario.endMinute,
          )
        : const TimeOfDay(hour: 7, minute: 0);

    IconData selectedIcon = currentScenario != null
        ? IconData(currentScenario.iconCode, fontFamily: 'MaterialIcons')
        : Icons.nights_stay;
    Color selectedColor = currentScenario != null
        ? Color(currentScenario.colorValue)
        : Colors.indigo;

    final List<Color> palette = [
      Colors.indigo,
      Colors.teal,
      Colors.deepPurple,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.lightGreen,
    ];

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
            title: Text(
              isEditing ? "Modifier le Scénario" : "Créer un Scénario",
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: sName,
                    decoration: const InputDecoration(
                      labelText: "Nom du scénario (ex: Nuit, Vacances...)",
                    ),
                    onChanged: (val) => sName = val,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "1. Icône et Couleur",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconsMap.values
                        .map(
                          (icon) => GestureDetector(
                            onTap: () =>
                                setPopupState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? selectedColor.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? selectedColor
                                      : Colors.grey,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: selectedIcon == icon
                                    ? selectedColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: palette
                        .map(
                          (c) => GestureDetector(
                            onTap: () => setPopupState(() => selectedColor = c),
                            child: CircleAvatar(
                              backgroundColor: c,
                              radius: 14,
                              child: selectedColor == c
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const Divider(height: 30),

                  const Text(
                    "2. Plage d'activation",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Définir une plage horaire"),
                    value: useTimeLimit,
                    activeColor: selectedColor,
                    onChanged: (val) =>
                        setPopupState(() => useTimeLimit = val!),
                  ),

                  if (useTimeLimit) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.green,
                      ),
                      title: const Text("Heure de début"),
                      trailing: Text(
                        startTime.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) setPopupState(() => startTime = time);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.red,
                      ),
                      title: const Text("Heure de fin"),
                      trailing: Text(
                        endTime.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) setPopupState(() => endTime = time);
                      },
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Le scénario restera actif jusqu'à l'arrêt manuel.",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const Divider(height: 30),

                  const Text(
                    "3. Action souhaitée",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: selectedTemp,
                    min: 15,
                    max: 28,
                    divisions: 26,
                    activeColor: selectedColor,
                    onChanged: (v) => setPopupState(() => selectedTemp = v),
                  ),
                  Center(
                    child: Text(
                      "${selectedTemp.toStringAsFixed(1)}°C",
                      style: TextStyle(
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "Appliquer sur :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._rooms.map(
                    (room) => CheckboxListTile(
                      activeColor: selectedColor,
                      title: Text(room.name),
                      value: selectedRooms.contains(room.name),
                      onChanged: (val) {
                        setPopupState(() {
                          val!
                              ? selectedRooms.add(room.name)
                              : selectedRooms.remove(room.name);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    final scenario = _scenarios[index];
                    if (scenario.id != null) {
                      try {
                        await BackendApi.instance.deleteScenario(scenario.id!);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                        return;
                      }
                    }

                    await _loadData();
                    AppLogger.log(
                      widget.userEmail,
                      "Scénario '$sName' supprimé",
                    );
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(this.context).pop();
                  },
                  child: const Text(
                    "SUPPRIMER",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (sName.isEmpty) return;
                  final updatedScenario = Scenario(
                    id: currentScenario?.id,
                    name: sName,
                    iconCode: selectedIcon.codePoint,
                    colorValue: selectedColor.toARGB32(),
                    startHour: startTime.hour,
                    startMinute: startTime.minute,
                    endHour: endTime.hour,
                    endMinute: endTime.minute,
                    roomNames: selectedRooms,
                    targetTemp: selectedTemp,
                    useTimeLimit: useTimeLimit,
                    isActive: currentScenario?.isActive ?? false,
                  );

                  final selectedNodeIds = _rooms
                      .where((room) => selectedRooms.contains(room.name))
                      .map((room) => room.id)
                      .whereType<int>()
                      .toList();

                  final payload = updatedScenario.toApiPayload(
                    username: widget.userEmail,
                    espNodeIds: selectedNodeIds,
                  );

                  try {
                    if (isEditing && updatedScenario.id != null) {
                      await BackendApi.instance.updateScenario(
                        updatedScenario.id!,
                        payload,
                      );
                    } else {
                      await BackendApi.instance.createScenario(payload);
                    }
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                    return;
                  }

                  await _loadData();
                  AppLogger.log(
                    widget.userEmail,
                    "Scénario '$sName' ${isEditing ? 'modifié' : 'créé'}",
                  );
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(this.context).pop();
                },
                child: Text(isEditing ? "METTRE À JOUR" : "SAUVEGARDER"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddRoom() {
    _nameController.clear();
    _cameraUrlController.clear();
    String? selEsp;
    Color selColor = Colors.blue;
    bool hasCamera = true; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
          List<String> remainingEsps = _availableEspHosts
              .where((ip) => !_rooms.any((room) => room.espIp == ip))
              .toList();

          return AlertDialog(
            title: const Text("Nouvelle pièce sur le plan"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Nom de la pièce"),
                  ),
                  const SizedBox(height: 20),
                  
                  if (remainingEsps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Aucun ESP32 détecté sur le réseau actuel.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Assigner ESP32",
                      ),
                      initialValue: selEsp,
                      items: remainingEsps
                          .map(
                            (ip) =>
                                DropdownMenuItem(value: ip, child: Text(ip)),
                          )
                          .toList(),
                      onChanged: (v) => setPopupState(() => selEsp = v),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // --- SWITCH CAMÉRA THERMIQUE ---
                  SwitchListTile(
                    title: const Text("Caméra thermique intégrée"),
                    subtitle: const Text("Désactiver si c'est un simple capteur Temp/Présence", style: TextStyle(fontSize: 11)),
                    value: hasCamera,
                    activeThumbColor: selColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setPopupState(() => hasCamera = val),
                  ),

                  // L'URL de la caméra n'apparaît QUE si l'interrupteur est activé !
                  if (hasCamera) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cameraUrlController,
                      decoration: const InputDecoration(
                        labelText: "URL du WebSocket thermique",
                        hintText: "ws://<ip-esp32>:81/",
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Optionnel: laisse vide si le port 81 est utilisé par défaut.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                            ]
                            .map(
                              (c) => GestureDetector(
                                onTap: () => setPopupState(() => selColor = c),
                                child: CircleAvatar(
                                  backgroundColor: c,
                                  radius: 15,
                                  child: selColor == c
                                      ? const Icon(
                                          Icons.check,
                                          size: 15,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: (selEsp == null || _nameController.text.isEmpty)
                    ? null
                    : () async {
                        final streamUrl =
                            _cameraUrlController.text.trim().isEmpty
                            ? 'ws://$selEsp:81/'
                            : _cameraUrlController.text.trim();

                        try {
                          await BackendApi.instance.createEspNode({
                            'username': widget.userEmail,
                            'ip_address': selEsp,
                            'room_name': _nameController.text.trim(),
                            'camera_url': hasCamera ? streamUrl : '',
                            'color_hex': '#${selColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
                            'has_camera': hasCamera,
                            'show_temperature': true,
                            'show_presence': true,
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                          return;
                        }

                        await _loadData();
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(this.context).pop();
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
        // --- NOUVEAU : Titre avec le nom en bleu SACHA ---
        title: Text.rich(
          TextSpan(
            text: "Plan de ",
            children: [
              TextSpan(
                text: widget.userEmail,
                style: const TextStyle(
                  color: Color(0xFF00B0FF), // Bleu SACHA
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_isScanningEsp32)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Analyser le réseau',
            onPressed: () => _refreshEsp32Discovery(),
          ),
          
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon Profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => ProfileScreen(
                  username: widget.userEmail, 
                  roomCount: _rooms.length, 
                  scenarioCount: _scenarios.length
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => SettingsScreen(userEmail: widget.userEmail),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_networkStatusMessage != null)
            Container(
              width: double.infinity,
              color: Colors.blueGrey.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _isScanningEsp32 ? Icons.radar : Icons.wifi,
                    size: 18,
                    color: Colors.blueGrey.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _networkStatusMessage!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ==========================================
          // 1. LE PLAN D'ARCHITECTE
          // ==========================================
          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                ? const Center(
                    child: Text(
                      "Plan vide.\nAppuyez sur le bouton pour ajouter une pièce.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : Stack(
                    children: _rooms.asMap().entries.map((entry) {
                      int index = entry.key;
                      Room room = entry.value;

                      return Positioned(
                        left: room.x,
                        top: room.y,
                        child: GestureDetector(
                          onPanUpdate: (details) => setState(() {
                            room.x += details.delta.dx;
                            room.y += details.delta.dy;
                          }),
                          onPanEnd: (details) => _persistRoomPosition(room),
                          child: SizedBox(
                            width: 240,
                            height: 180,
                            child: RoomCard(
                              room: room,
                              onDelete: () => _confirmDelete(index),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // ==========================================
          // 2. LA BARRE DES SCÉNARIOS
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
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 15, right: 15, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mes Scénarios",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showScenarioForm(),
                        icon: const Icon(Icons.bolt, color: Color(0xFF00B0FF), size: 22), 
                        label: const Text(
                          "Créer un scénario", 
                          style: TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold, fontSize: 14) 
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF00B0FF).withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: _scenarios.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucun scénario configuré",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: _scenarios.length,
                          itemBuilder: (context, index) {
                            final scenario = _scenarios[index];
                            final color = Color(scenario.colorValue);

                            return GestureDetector(
                              onTap: () => _toggleScenario(index),
                              child: Stack(
                                children: [
                                  // LA CARTE DU SCÉNARIO
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 120,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scenario.isActive
                                          ? color.withOpacity(0.25)
                                          : color.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: scenario.isActive
                                            ? color
                                            : color.withOpacity(0.3),
                                        width: 1.0, 
                                      ),
                                      boxShadow: scenario.isActive
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          IconData(
                                            scenario.iconCode,
                                            fontFamily: 'MaterialIcons',
                                          ),
                                          color: scenario.isActive
                                              ? color
                                              : color.withOpacity(0.6),
                                          size: 28,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          scenario.name,
                                          style: TextStyle(
                                            color: scenario.isActive
                                                ? color
                                                : color.withOpacity(0.6),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // LE BOUTON D'INFORMATION / ÉDITION
                                  Positioned(
                                    top: 12,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () => _showScenarioForm(index),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: color,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // --- Le bouton étendu avec le texte "Ajouter une pièce" ---
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "btnRoom",
        backgroundColor: const Color(0xFF00B0FF), // Ton bleu SACHA
        elevation: 6,
        onPressed: _showAddRoom,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Ajouter une pièce",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}