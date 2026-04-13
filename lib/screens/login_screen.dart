// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart'; // Import de la nouvelle page
import '../utils/mock_db.dart'; // Import de notre base de données

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleSignIn() {
    final identifiant = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifiant.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return;
    }

    // On vérifie si l'utilisateur existe
    if (MockDB.users.containsKey(identifiant)) {
      final userData = MockDB.users[identifiant]!;
      
      // On vérifie le mot de passe
      if (userData['password'] == password) {
        
        // --- NOUVEAUTÉ : ON VÉRIFIE LA VALIDATION ---
        if (userData['isValidated'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // L'utilisateur existe, le mdp est bon, mais pas de validation
          _showSnackBar("Votre compte n'est pas encore validé. Vérifiez vos emails.", Colors.orange);
        }
        
      } else {
        _showSnackBar("Identifiant ou mot de passe incorrect", Colors.redAccent);
      }
    } else {
      _showSnackBar("Identifiant ou mot de passe incorrect", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/sacha.png', height: 80, errorBuilder: (c, e, s) => const Text("SACHA", style: TextStyle(fontSize: 40, color: Color(0xFF00B0FF)))),
              const SizedBox(height: 60),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Identifiant", prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 25),

              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(colors: [Color(0xFF00B0FF), Color(0xFF00E676)]),
                ),
                child: ElevatedButton(
                  onPressed: _handleSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              
              // --- BOUTON POUR ALLER SUR LA PAGE D'INSCRIPTION ---
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text("Pas de compte ? Créer un profil SACHA", style: TextStyle(color: Colors.blueGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}