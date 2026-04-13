// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../utils/mock_db.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  void _handleRegister() {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return;
    }

    if (MockDB.users.containsKey(email)) {
      _showSnackBar("Un compte existe déjà avec cet email", Colors.redAccent);
      return;
    }

    // 1. On crée le compte avec le statut NON VALIDÉ
    setState(() {
      MockDB.users[email] = {
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'isValidated': false, // Le compte est bloqué par défaut
      };
    });

    // 2. On simule l'envoi de l'email avec un bouton pour le valider manuellement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Email de validation envoyé à $email."),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: "SIMULER LE CLIC (VALIDER)",
          textColor: Colors.greenAccent,
          onPressed: () {
            // Quand tu cliques ici, le compte devient valide !
            setState(() => MockDB.users[email]!['isValidated'] = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Compte validé avec succès !"), backgroundColor: Colors.green),
            );
          },
        ),
      ),
    );

    // Retour à la page de connexion
    Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueGrey),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              const Text("Créer un profil", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 40),
              
              TextField(controller: _prenomController, decoration: const InputDecoration(labelText: "Prénom")),
              const SizedBox(height: 20),
              TextField(controller: _nomController, decoration: const InputDecoration(labelText: "Nom")),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email / Identifiant")),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(colors: [Color(0xFF00B0FF), Color(0xFF00E676)]),
                ),
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: const Text("S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}