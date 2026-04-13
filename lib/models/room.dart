import 'package:flutter/material.dart';

class Room {
  String name;
  final String espIp;
  final Color color;
  double temperature;
  double lastKnownTemperature;
  bool isOccupied;
  bool showTemperature; 
  bool showPresence;
  bool isFroidAlerte; // <--- LA VARIABLE MANQUANTE EST ICI

  Room({
    required this.name,
    required this.espIp,
    required this.color,
    this.temperature = 0.0,
    this.lastKnownTemperature = 0.0,
    this.isOccupied = false,
    this.showTemperature = true,
    this.showPresence = true,
    this.isFroidAlerte = false, // Par défaut, pas d'alerte
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'espIp': espIp,
      'color': color.value,
      'temperature': temperature,
      'lastKnownTemperature': lastKnownTemperature,
      'isOccupied': isOccupied,
      'showTemperature': showTemperature,
      'showPresence': showPresence,
      'isFroidAlerte': isFroidAlerte, // On la sauvegarde
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      name: map['name'],
      espIp: map['espIp'],
      color: Color(map['color']),
      temperature: map['temperature']?.toDouble() ?? 0.0,
      lastKnownTemperature: map['lastKnownTemperature']?.toDouble() ?? 0.0,
      isOccupied: map['isOccupied'] ?? false,
      showTemperature: map['showTemperature'] ?? true,
      showPresence: map['showPresence'] ?? true,
      isFroidAlerte: map['isFroidAlerte'] ?? false, // On la charge
    );
  }
}