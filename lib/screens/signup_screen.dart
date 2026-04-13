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

  void _register() {
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) return;

    setState(() {
      MockDB.users[email] = {
        'password': _passwordController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'nom': _nomController.text.trim(),
        'isValidated': false,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Email de validation envoyé à $email"),
      action: SnackBarAction(label: "VALIDER", onPressed: () => MockDB.users[email]!['isValidated'] = true),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            TextField(controller: _prenomController, decoration: const InputDecoration(labelText: "Prénom")),
            TextField(controller: _nomController, decoration: const InputDecoration(labelText: "Nom")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Mot de passe"), obscureText: true),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _register, child: const Text("S'INSCRIRE")),
          ],
        ),
      ),
    );
  }
}