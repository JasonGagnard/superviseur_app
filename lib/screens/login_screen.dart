import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../services/backend_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showMsg("Veuillez remplir les champs", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await BackendApi.instance.login(
        username: email,
        password: pass,
      );

      final user = response['user'] as Map<String, dynamic>?;
      final isValidated = user?['is_validated'] as bool? ?? false;

      if (!mounted) {
        return;
      }

      if (isValidated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userEmail: email)),
        );
      } else {
        _showMsg("Compte non validé. Vérifiez vos emails.", Colors.orange);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showMsg(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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