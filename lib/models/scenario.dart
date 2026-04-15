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
  bool useTimeLimit; // Nouveau : Détermine si on suit l'horloge ou non

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
    this.useTimeLimit = true,
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
      'useTimeLimit': useTimeLimit,
    };
  }

  factory Scenario.fromMap(Map<String, dynamic> map) {
    return Scenario(
      name: map['name'] ?? '',
      iconCode: map['iconCode'] ?? 0,
      colorValue: map['colorValue'] ?? 0xFF000000,
      startHour: map['startH'] ?? 0,
      startMinute: map['startM'] ?? 0,
      endHour: map['endH'] ?? 0,
      endMinute: map['endM'] ?? 0,
      roomNames: List<String>.from(map['rooms'] ?? []),
      targetTemp: (map['temp'] ?? 21.0).toDouble(),
      isActive: map['isActive'] ?? false,
      useTimeLimit: map['useTimeLimit'] ?? true,
    );
  }
}
