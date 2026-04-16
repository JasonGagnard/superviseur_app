import 'dart:async';

import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/live_thermal_stream.dart';
import '../services/backend_api.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  ThermalFrameStats? _liveStats;
  Timer? _inferenceCooldownTimer;
  bool _isInferenceRunning = false;
  DateTime? _lastInferenceTime;
  List<double>? _pendingInferenceFrame;

  @override
  void dispose() {
    _inferenceCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncRoomDisplayPrefs() async {
    if (widget.room.id == null) {
      return;
    }

    try {
      await BackendApi.instance.updateEspNode(widget.room.id!, {
        'show_temperature': widget.room.showTemperature,
        'show_presence': widget.room.showPresence,
      });
    } catch (_) {
      // Ignore API failure to keep detail interactions smooth.
    }
  }

  void _handleThermalFrame(List<double> frame) {
    if (!widget.room.hasCamera) {
      return;
    }

    _pendingInferenceFrame = frame;
    _scheduleThermalInference();
  }

  void _scheduleThermalInference() {
    if (_isInferenceRunning) {
      return;
    }

    final lastInferenceTime = _lastInferenceTime;
    if (lastInferenceTime != null &&
        DateTime.now().difference(lastInferenceTime).inSeconds < 8) {
      _inferenceCooldownTimer?.cancel();
      _inferenceCooldownTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          _scheduleThermalInference();
        }
      });
      return;
    }

    final frame = _pendingInferenceFrame;
    if (frame == null || frame.length != 32 * 24) {
      return;
    }

    _pendingInferenceFrame = null;
    _isInferenceRunning = true;
    _lastInferenceTime = DateTime.now();

    BackendApi.instance
        .detectPresenceFromThermalFrame(frame)
        .then((result) {
          if (!mounted) {
            return;
          }

          setState(() {
            widget.room.isOccupied = (result['human_count'] as num? ?? 0) > 0;
          });
        })
        .catchError((_) {
          // Keep the current presence state if inference is temporarily unavailable.
        })
        .whenComplete(() {
          _isInferenceRunning = false;
          if (_pendingInferenceFrame != null && mounted) {
            _scheduleThermalInference();
          }
        });
  }

  String _formatTemperature(double value) => '${value.toStringAsFixed(1)}°C';

  // Fonction pour ouvrir la caméra thermique en plein écran (HUD mode)
  void _openFullScreenThermal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: LiveThermalStream(
                streamUrl: widget.room.cameraStreamUrl,
                accentColor: widget.room.color,
                onStats: (stats) {
                  setState(() {
                    _liveStats = stats;
                    widget.room.temperature = stats.currentTemperature;
                    widget.room.lastKnownTemperature = stats.currentTemperature;
                  });
                },
              ),
            ),

            // Interface superposée (HUD)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 35,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Badge(
                          label: Text("LIVE THERMAL"),
                          backgroundColor: Colors.red,
                          largeSize: 20,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Panneau d'informations en bas du plein écran
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _hudItem(
                            Icons.person,
                            "PERSONNES",
                            widget.room.isOccupied ? "1" : "0",
                          ),
                          _hudItem(
                            Icons.vertical_align_top,
                            "MAX",
                            _liveStats != null
                                ? _formatTemperature(_liveStats!.maxTemperature)
                                : _formatTemperature(widget.room.temperature),
                          ),
                          _hudItem(
                            Icons.vertical_align_bottom,
                            "MIN",
                            _liveStats != null
                                ? _formatTemperature(_liveStats!.minTemperature)
                                : _formatTemperature(widget.room.temperature),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Petit composant pour les données du plein écran
  Widget _hudItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pièce : ${widget.room.name}"),
        backgroundColor: widget.room.color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Options d'affichage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              title: const Text("Afficher la température"),
              secondary: const Icon(Icons.thermostat, color: Colors.orange),
              value: widget.room.showTemperature,
              onChanged: (val) {
                setState(() => widget.room.showTemperature = val);
                _syncRoomDisplayPrefs();
              },
            ),

            SwitchListTile(
              title: const Text("Afficher la présence"),
              secondary: const Icon(Icons.person, color: Colors.blue),
              value: widget.room.showPresence,
              onChanged: (val) {
                setState(() => widget.room.showPresence = val);
                _syncRoomDisplayPrefs();
              },
            ),

            const Divider(height: 40),

            const Text(
              "Vision Thermique",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Appuyez sur l'image pour agrandir",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            // Widget Caméra thermique cliquable
            GestureDetector(
              onTap: () => _openFullScreenThermal(context),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: widget.room.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LiveThermalStream(
                        streamUrl: widget.room.cameraStreamUrl,
                        accentColor: widget.room.color,
                        onFrame: _handleThermalFrame,
                        onStats: (stats) {
                          setState(() {
                            _liveStats = stats;
                            widget.room.temperature = stats.currentTemperature;
                            widget.room.lastKnownTemperature =
                                stats.currentTemperature;
                          });
                        },
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Capteurs additionnels",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _sensorRow(Icons.water_drop, "Humidité", "45%"),
            _sensorRow(Icons.lightbulb, "Luminosité", "320 lux"),
            _sensorRow(Icons.wifi, "Signal ESP32", "-65 dBm"),
          ],
        ),
      ),
    );
  }

  Widget _sensorRow(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: widget.room.color),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
