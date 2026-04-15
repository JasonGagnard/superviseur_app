import 'dart:async';

import 'package:flutter/material.dart';
import '../models/room.dart';
import 'live_thermal_stream.dart';
import '../screens/room_stats_screen.dart'; 
import '../utils/esp32_discovery.dart';
import '../utils/notification_service.dart'; 

class RoomCard extends StatefulWidget {
  final Room room;
  final VoidCallback onDelete;

  const RoomCard({super.key, required this.room, required this.onDelete});

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  ThermalFrameStats? _liveStats;
  Timer? _espPresenceTimer;
  bool _isCheckingEspPresence = true;
  bool _isEspOnline = false;
  DateTime? _lastAlertTime; 

  String _formatTemperature(double value) => '${value.toStringAsFixed(1)}°C';

  @override
  void initState() {
    super.initState();
    _refreshEspPresence();
    _espPresenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshEspPresence(),
    );
  }

  @override
  void didUpdateWidget(covariant RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.espIp != widget.room.espIp) {
      _refreshEspPresence();
    }
  }

  @override
  void dispose() {
    _espPresenceTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshEspPresence() async {
    final host = widget.room.espIp.trim();
    if (host.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingEspPresence = false;
        _isEspOnline = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingEspPresence = true;
      });
    }

    final isOnline = await isEsp32Reachable(host);
    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingEspPresence = false;
      _isEspOnline = isOnline;
    });
  }

  Widget _buildEspStatusChip() {
    final color = _isCheckingEspPresence
        ? Colors.orangeAccent
        : (_isEspOnline ? Colors.greenAccent : Colors.redAccent);
    final icon = _isCheckingEspPresence
        ? Icons.sync
        : (_isEspOnline ? Icons.check_circle : Icons.cancel);
    final label = _isCheckingEspPresence
        ? 'Vérification...'
        : (_isEspOnline ? 'ESP32 détecté' : 'ESP32 absent');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double displayTemperature =
        _liveStats?.currentTemperature ?? widget.room.temperature;

    return InkWell(
      onTap: () => _showRoomDetails(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: widget.room.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.room.color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.room.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.room.color.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoomStatsScreen(room: widget.room),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(
                          Icons.bar_chart,
                          color: Colors.blueGrey,
                          size: 22,
                        ),
                      ),
                    ),

                    if (widget.room.isFroidAlerte)
                      const Icon(Icons.ac_unit, color: Colors.blue, size: 18),
                    if (widget.room.isFroidAlerte) const SizedBox(width: 4),
                    if (widget.room.showPresence)
                      Icon(
                        widget.room.isOccupied
                            ? Icons.person
                            : Icons.person_outline,
                        color: widget.room.isOccupied
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            if (widget.room.showTemperature)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayTemperature.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2),
                    child: Text("°C", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.room.espIp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildEspStatusChip(),
                  ],
                ),
                // --- CONDITION : Bouton Live affiché uniquement si caméra présente ---
                if (widget.room.hasCamera)
                  InkWell(
                    onTap: () => _showCameraView(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.room.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            color: widget.room.color,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Live",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraView(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16.0),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.videocam, color: widget.room.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Thermique : ${widget.room.name}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.room.color, width: 3),
                      ),
                      child: LiveThermalStream(
                        streamUrl: widget.room.cameraStreamUrl,
                        accentColor: widget.room.color,
                        onStats: (stats) {
                          setDialogState(() {
                            double oldTemp = widget.room.temperature;
                            double newTemp = stats.currentTemperature;
                            double delta = newTemp - oldTemp;

                            bool canAlert = _lastAlertTime == null || DateTime.now().difference(_lastAlertTime!).inMinutes > 5;

                            if (canAlert && oldTemp != 20.0) {
                              if (delta >= 2.5 || newTemp > 30.0) {
                                NotificationService.showTemperatureAlert(
                                  roomName: widget.room.name, 
                                  alertType: 'HAUSSE', 
                                  temperature: newTemp
                                );
                                _lastAlertTime = DateTime.now();
                              } 
                              else if (delta <= -2.5 || newTemp < 10.0) {
                                NotificationService.showTemperatureAlert(
                                  roomName: widget.room.name, 
                                  alertType: 'BAISSE', 
                                  temperature: newTemp
                                );
                                _lastAlertTime = DateTime.now();
                              }
                            }

                            _liveStats = stats;
                            widget.room.temperature = stats.currentTemperature;
                            widget.room.lastKnownTemperature = stats.currentTemperature;
                            widget.room.temperature = newTemp;
                            widget.room.lastKnownTemperature = newTemp;
                          });
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildCamInfoRow(
                          Icons.people,
                          "Personnes détectées",
                          widget.room.isOccupied ? "1 personne" : "Aucune",
                        ),
                        const Divider(color: Colors.white12),
                        _buildCamInfoRow(
                          Icons.arrow_downward,
                          "Température Min",
                          _liveStats != null
                              ? _formatTemperature(_liveStats!.minTemperature)
                              : _formatTemperature(widget.room.temperature),
                        ),
                        const Divider(color: Colors.white12),
                        _buildCamInfoRow(
                          Icons.arrow_upward,
                          "Température Max",
                          _liveStats != null
                              ? _formatTemperature(_liveStats!.maxTemperature)
                              : _formatTemperature(widget.room.temperature),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCamInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white54)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: widget.room.color),
            const SizedBox(width: 10),
            Text(widget.room.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.wifi, "IP ESP32", widget.room.espIp),
            // --- CONDITION : URL Websocket affichée uniquement si caméra présente ---
            if (widget.room.hasCamera)
              _buildDetailRow(
                Icons.wifi_tethering,
                "WebSocket Caméra",
                widget.room.cameraStreamUrl,
              ),
            _buildDetailRow(
              Icons.thermostat,
              "Temp. Actuelle",
              _formatTemperature(
                _liveStats?.currentTemperature ?? widget.room.temperature,
              ),
            ),
            _buildDetailRow(
              Icons.history,
              "Dernière Connue",
              _formatTemperature(widget.room.lastKnownTemperature),
            ),
            _buildDetailRow(
              widget.room.isOccupied ? Icons.person : Icons.person_outline,
              "Occupation",
              widget.room.isOccupied ? "Présence" : "Vide",
            ),
            if (widget.room.isFroidAlerte)
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Alerte Température !",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  "SUPPRIMER CETTE PIÈCE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label : ", style: const TextStyle(color: Colors.blueGrey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}