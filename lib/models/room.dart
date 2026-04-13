import 'package:flutter/material.dart';

class Room {
  String name;
  final String espIp;
  final Color color;
  double temperature;
  double lastKnownTemperature; // Pour comparer et détecter une chute
  bool isOccupied;

  bool showTemperature; 
  bool showPresence;

  Room({
    required this.name,
    required this.espIp,
    required this.color,
    this.temperature = 0.0,
    this.lastKnownTemperature = 0.0,
    this.isOccupied = false,
    this.showTemperature = true,
    this.showPresence = true,
  });

  // Déclenche l'alerte si la température a chuté de plus de 2°C
  bool get isFroidAlerte {
    return (lastKnownTemperature - temperature) > 2.0;
  }
}