import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Ouvrir',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    // LA CORRECTION EST ICI : Le paramètre s'appelle "settings:"
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static Future<void> showTemperatureAlert({
    required String roomName,
    required String alertType,
    required double temperature,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sacha_thermal_alerts', 
      'Alertes Thermiques SACHA', 
      channelDescription: 'Notifications pour les variations de température critiques',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFE53935),
      playSound: true,
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      linux: linuxDetails,
    );

    String title = alertType == 'HAUSSE' ? '🔥 Alerte Surchauffe : $roomName' : '❄️ Chute de température : $roomName';
    String body = alertType == 'HAUSSE' 
        ? 'Hausse anormale détectée. Température actuelle : ${temperature.toStringAsFixed(1)}°C.' 
        : 'Baisse soudaine détectée (Fenêtre ouverte ?). Température actuelle : ${temperature.toStringAsFixed(1)}°C.';

    // LA CORRECTION EST ICI : Utilisation stricte des paramètres nommés
    await _notificationsPlugin.show(
      id: roomName.hashCode, 
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}