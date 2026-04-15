import 'package:flutter/material.dart';

class Room {
  String name;
  final String espIp;
  final String cameraUrl;
  final Color color;
  double temperature;
  double lastKnownTemperature;
  bool isOccupied;
  bool showTemperature;
  bool showPresence;
  bool isFroidAlerte;
  bool hasCamera; // <-- NOUVEAU : Indique si la pièce possède une caméra

  // Coordonnées pour le plan architecte
  double x;
  double y;

  Room({
    required this.name,
    required this.espIp,
    this.cameraUrl = '',
    required this.color,
    this.temperature = 20.0,
    this.lastKnownTemperature = 20.0,
    this.isOccupied = false,
    this.showTemperature = true,
    this.showPresence = true,
    this.isFroidAlerte = false,
    this.hasCamera = true, // <-- Par défaut sur true pour rétrocompatibilité
    this.x = 50.0, 
    this.y = 50.0, 
  });

  String get cameraStreamUrl {
    final value = cameraUrl.trim().isNotEmpty ? cameraUrl.trim() : espIp.trim();
    if (value.isEmpty) {
      return '';
    }

    final normalizedValue = value.contains('://') ? value : 'ws://$value';

    final uri = Uri.tryParse(normalizedValue);
    if (uri == null) {
      return normalizedValue;
    }

    final scheme = uri.scheme == 'http'
        ? 'ws'
        : uri.scheme == 'https'
        ? 'wss'
        : uri.scheme;
    final path =
        uri.path.isEmpty ||
            uri.path == '/' ||
            uri.path == '/81' ||
            uri.path == '81'
        ? '/'
        : uri.path;

    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : 81,
      path: path,
      query: uri.query,
    ).toString();
  }

  // Transformation en JSON pour la sauvegarde
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'espIp': espIp,
      'cameraUrl': cameraUrl,
      'color': color.toARGB32(),
      'temperature': temperature,
      'lastKnownTemperature': lastKnownTemperature,
      'isOccupied': isOccupied,
      'showTemperature': showTemperature,
      'showPresence': showPresence,
      'isFroidAlerte': isFroidAlerte,
      'hasCamera': hasCamera, // <-- Sauvegarde
      'x': x,
      'y': y,
    };
  }

  // Création d'une pièce à partir des données sauvegardées
  factory Room.fromMap(Map<String, dynamic> map) {
    final colorValue = map['color'] as int;
    return Room(
      name: map['name'],
      espIp: map['espIp'],
      cameraUrl: map['cameraUrl']?.toString() ?? '',
      color: Color.fromARGB(
        (colorValue >> 24) & 0xFF,
        (colorValue >> 16) & 0xFF,
        (colorValue >> 8) & 0xFF,
        colorValue & 0xFF,
      ),
      temperature: map['temperature']?.toDouble() ?? 20.0,
      lastKnownTemperature: map['lastKnownTemperature']?.toDouble() ?? 20.0,
      isOccupied: map['isOccupied'] ?? false,
      showTemperature: map['showTemperature'] ?? true,
      showPresence: map['showPresence'] ?? true,
      isFroidAlerte: map['isFroidAlerte'] ?? false,
      hasCamera: map['hasCamera'] ?? true, // <-- Récupération
      x: map['x']?.toDouble() ?? 50.0,
      y: map['y']?.toDouble() ?? 50.0,
    );
  }
}