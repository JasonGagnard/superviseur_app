import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  // Plus besoin de Supabase.initialize ici
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