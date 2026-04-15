class Scenario {
  int? id;
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
    this.id,
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
      'id': id,
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
      id: map['id'] as int?,
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

  factory Scenario.fromApi(Map<String, dynamic> map) {
    final espNodes = (map['esp_nodes'] as List<dynamic>? ?? const []);
    return Scenario(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      iconCode: (map['icon_code'] as num?)?.toInt() ?? 0,
      colorValue: (map['color_value'] as num?)?.toInt() ?? 0xFF000000,
      startHour: (map['start_hour'] as num?)?.toInt() ?? 0,
      startMinute: (map['start_minute'] as num?)?.toInt() ?? 0,
      endHour: (map['end_hour'] as num?)?.toInt() ?? 0,
      endMinute: (map['end_minute'] as num?)?.toInt() ?? 0,
      roomNames: espNodes
          .map((node) => (node as Map)['room_name']?.toString())
          .whereType<String>()
          .toList(),
      targetTemp: (map['target_temp'] as num?)?.toDouble() ?? 21.0,
      isActive: map['is_active'] as bool? ?? false,
      useTimeLimit: map['use_time_limit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toApiPayload({
    required String username,
    required List<int> espNodeIds,
  }) {
    return {
      'username': username,
      'name': name,
      'description': name,
      'is_active': isActive,
      'icon_code': iconCode,
      'color_value': colorValue,
      'start_hour': startHour,
      'start_minute': startMinute,
      'end_hour': endHour,
      'end_minute': endMinute,
      'target_temp': targetTemp,
      'use_time_limit': useTimeLimit,
      'esp_node_ids': espNodeIds,
    };
  }
}
