import 'dart:io'; // <-- NOUVEAU
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- NOUVEAU
import '../utils/mock_db.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isObscured = true;
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

  void _handleSignUp() {
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

    if (MockDB.users.containsKey(username)) {
      _showMsg("Ce nom d'utilisateur est déjà pris", Colors.orange);
      return;
    }

    // --- MISE À JOUR SAUVEGARDE : Ajout des infos dans MockDB ---
    setState(() {
      MockDB.users[username] = {
        'firstName': firstName, // <-- SAUVEGARDE
        'lastName': lastName,   // <-- SAUVEGARDE
        'email': email,
        'password': pass,
        // On stocke le chemin de l'image si elle existe
        'profileImagePath': _imageFile?.path, // <-- SAUVEGARDE
        'isValidated': true,
      };
    });

    _showMsg("Compte créé avec succès !", Colors.green);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
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
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B0FF), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                  ),
                  child: const Text("S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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