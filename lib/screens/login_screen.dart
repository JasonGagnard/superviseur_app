import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../utils/mock_db.dart';

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
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (MockDB.users.containsKey(email) && MockDB.users[email]!['password'] == pass) {
      if (MockDB.users[email]!['isValidated'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userEmail: email)),
        );
      } else {
        _showMsg("Compte non validé. Vérifiez vos emails.", Colors.orange);
      }
    } else {
      _showMsg("Identifiants incorrects", Colors.redAccent);
    }
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Image.asset('assets/sacha.png', height: 80, errorBuilder: (c,e,s) => const Text("SACHA", style: TextStyle(fontSize: 40, color: Color(0xFF00B0FF)))),
              const SizedBox(height: 60),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email / Identifiant")),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isObscured = !_isObscured)),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _handleSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())), child: const Text("Créer un compte SACHA")),
            ],
          ),
        ),
      ),
    );
  }
}