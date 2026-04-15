import 'dart:io'; // <-- NOUVEAU
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- NOUVEAU
import '../services/backend_api.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isObscured = true;
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController(); // <-- NOUVEAU
  final _lastNameController = TextEditingController(); // <-- NOUVEAU
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _imageFile; // <-- NOUVEAU : Stocke l'image sélectionnée
  final ImagePicker _picker = ImagePicker(); // <-- NOUVEAU : Outil de sélection

  // --- NOUVEAU : FONCTION POUR CHOISIR UNE IMAGE ---
  Future<void> _pickImage() async {
    // Affiche un dialogue pour choisir Source : Caméra ou Galerie
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisir une photo de profil"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text("Appareil photo"),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text("Galerie photo"),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500, // On réduit la taille pour pas surcharger la mémoire
        maxHeight: 500,
        imageQuality: 80, // Compression légère
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    final username = _usernameController.text.trim();
    final firstName = _firstNameController.text.trim(); // <-- NOUVEAU
    final lastName = _lastNameController.text.trim(); // <-- NOUVEAU
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    // Vérification des champs obligatoires
    if (username.isEmpty || email.isEmpty || pass.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _showMsg("Veuillez remplir tous les champs (photo optionnelle)", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await BackendApi.instance.signup(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: pass,
        profileImagePath: _imageFile?.path,
      );

      if (!mounted) {
        return;
      }

      _showMsg("Compte créé avec succès !", Colors.green);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00B0FF)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Image.asset('assets/sacha.png', height: 80, errorBuilder: (c,e,s) => const Text("SACHA", style: TextStyle(fontSize: 40, color: Color(0xFF00B0FF)))),
              const SizedBox(height: 30),

              // ==========================================
              // NOUVEAU : L'ESPACE PHOTO CIRCULAIRE
              // ==========================================
              GestureDetector(
                onTap: _pickImage, // Clique pour changer la photo
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      // Si une image est choisie, on l'affiche, sinon on affiche l'icône par défaut
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.account_circle, size: 120, color: Color(0xFF00B0FF))
                          : null,
                    ),
                    // Petit bouton "éditer" en bas à droite
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B0FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Champ Nom d'utilisateur
              TextField(
                controller: _usernameController, 
                decoration: const InputDecoration(labelText: "Nom d'utilisateur")
              ),
              const SizedBox(height: 15),

              // --- NOUVEAU : CHAMPS NOM ET PRÉNOM ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController, 
                      decoration: const InputDecoration(labelText: "Prénom"),
                      textCapitalization: TextCapitalization.words, // Première lettre majuscule
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController, 
                      decoration: const InputDecoration(labelText: "Nom"),
                      textCapitalization: TextCapitalization.characters, // Tout en majuscule
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Champ Email
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "Email")
              ),
              const SizedBox(height: 15),
              
              // Champ Mot de passe
              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), 
                    onPressed: () => setState(() => _isObscured = !_isObscured)
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Bouton S'INSCRIRE (Design conservé)
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B0FF), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30), 
            ],
          ),
        ),
      ),
    );
  }
}