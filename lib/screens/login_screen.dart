import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false; // Pour afficher un chargement
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Fonction de connexion Supabase
  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw 'Veuillez remplir tous les champs';
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.redAccent);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fonction d'inscription (Optionnelle mais utile au début)
  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showSnackBar("Compte créé ! Connectez-vous.", Colors.green);
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
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
              Image.asset(
                'assets/sacha.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Text(
                  "SACHA",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF), letterSpacing: 3),
                ),
              ),
              const SizedBox(height: 60),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueGrey, size: 20),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF26C6DA), width: 2)),
                ),
              ),
              const SizedBox(height: 25),

              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueGrey, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF26C6DA), width: 2)),
                ),
              ),
              const SizedBox(height: 60),

              // Bouton Connexion
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B0FF), Color(0xFF00E676)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Lien Inscription
              TextButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: const Text(
                  "Pas de compte ? Créer un profil SACHA",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}