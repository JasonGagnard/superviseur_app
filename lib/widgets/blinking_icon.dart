import 'package:flutter/material.dart';

class BlinkingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const BlinkingIcon({
    super.key,
    required this.icon,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  State<BlinkingIcon> createState() => _BlinkingIconState();
}

class _BlinkingIconState extends State<BlinkingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Crée le contrôleur d'animation (vitesse du clignotement)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true); // Répète l'animation en boucle
  }

  @override
  void dispose() {
    _controller.dispose(); // Très important pour la mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller, // Applique l'effet de fondu
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}