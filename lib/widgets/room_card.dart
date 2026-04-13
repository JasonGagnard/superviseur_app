import 'package:flutter/material.dart';
import '../models/room.dart';
import '../screens/room_detail_screen.dart';
import 'blinking_icon.dart';

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RoomDetailScreen(room: room)),
          );
          (context as Element).markNeedsBuild();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [room.color.withOpacity(0.85), room.color],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (room.showTemperature)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.thermostat, color: Colors.white, size: 24),
                              Text("${room.temperature.toStringAsFixed(1)}°", 
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        if (room.showPresence)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(room.isOccupied ? Icons.person : Icons.person_outline, color: Colors.white, size: 36),
                              Text(room.isOccupied ? "OCCUPÉ" : "VIDE", 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Affichage du flocon clignotant si alerte
              if (room.isFroidAlerte)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: BlinkingIcon(
                    icon: Icons.ac_unit, // Flocon
                    color: Colors.white,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}