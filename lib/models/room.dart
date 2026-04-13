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
  bool isFroidAlerte;
  
  // Coordonnées pour le plan architecte
  double x;
  double y;

  Room({
    required this.name,
    required this.espIp,
    required this.color,
    this.temperature = 20.0,
    this.lastKnownTemperature = 20.0,
    this.isOccupied = false,
    this.showTemperature = true,
    this.showPresence = true,
    this.isFroidAlerte = false,
    this.x = 50.0, // Position par défaut
    this.y = 50.0, // Position par défaut
  });

  // Transformation en JSON pour la sauvegarde
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
      'isFroidAlerte': isFroidAlerte,
      'x': x,
      'y': y,
    };
  }

  // Création d'une pièce à partir des données sauvegardées
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      name: map['name'],
      espIp: map['espIp'],
      color: Color(map['color']),
      temperature: map['temperature']?.toDouble() ?? 20.0,
      lastKnownTemperature: map['lastKnownTemperature']?.toDouble() ?? 20.0,
      isOccupied: map['isOccupied'] ?? false,
      showTemperature: map['showTemperature'] ?? true,
      showPresence: map['showPresence'] ?? true,
      isFroidAlerte: map['isFroidAlerte'] ?? false,
      x: map['x']?.toDouble() ?? 50.0,
      y: map['y']?.toDouble() ?? 50.0,
    );
  }
}