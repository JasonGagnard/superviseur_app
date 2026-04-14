import 'package:flutter/material.dart';

class Scenario {
  String name;
  int iconCode; 
  int colorValue;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  List<String> roomNames;
  double targetTemp;
  bool isActive;

  Scenario({
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.roomNames,
    required this.targetTemp,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'startH': startHour,
      'startM': startMinute,
      'endH': endHour,
      'endM': endMinute,
      'rooms': roomNames,
      'temp': targetTemp,
      'isActive': isActive,
    };
  }

  factory Scenario.fromMap(Map<String, dynamic> map) {
    return Scenario(
      name: map['name'],
      iconCode: map['iconCode'],
      colorValue: map['colorValue'],
      startHour: map['startH'],
      startMinute: map['startM'],
      endHour: map['endH'],
      endMinute: map['endM'],
      roomNames: List<String>.from(map['rooms']),
      targetTemp: map['temp']?.toDouble() ?? 21.0,
      isActive: map['isActive'] ?? false,
    );
  }
}