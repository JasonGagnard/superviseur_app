import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://mqwjgmzxpevjegvrmbvs.supabase.co', // URL corrigée
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2pnbXp4cGV2amVndnJtYnZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyMDEwMTYsImV4cCI6MjA4Nzc3NzAxNn0.ipDylihOYJFEaEb0qaIYfs5xI4iYCJ26HIZDsLtoQZg',
  );

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
      home: LoginScreen(),
    );
  }
}