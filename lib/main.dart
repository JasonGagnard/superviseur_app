import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/notification_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Assure que Flutter est prêt
  await NotificationService.initialize();    // Initialise les notifications
  
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SACHA Superviseur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}