import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onDelete;

  const RoomCard({
    super.key,
    required this.room,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showRoomDetails(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: room.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: room.color.withOpacity(0.5), width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LIGNE DU HAUT : Nom et Icônes de statut ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: room.color.withOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (room.isFroidAlerte)
                      const Icon(Icons.ac_unit, color: Colors.blue, size: 18),
                    if (room.isFroidAlerte) const SizedBox(width: 4),
                    if (room.showPresence)
                      Icon(
                        room.isOccupied ? Icons.person : Icons.person_outline,
                        color: room.isOccupied ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            
            // --- MILIEU : Affichage de la Température ---
            if (room.showTemperature)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.temperature.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 2),
                    child: Text("°C", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              
            const Spacer(),
            
            // --- LIGNE DU BAS : IP ESP32 et Bouton Caméra ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.espIp,
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
                
                // LE NOUVEAU BOUTON CAMÉRA
                InkWell(
                  onTap: () => _showCameraView(context), // Ouvre la vue Caméra
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.blueGrey, size: 18),
                        SizedBox(width: 4),
                        Text("Live", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. LA NOUVELLE VUE CAMÉRA (MONITEUR NOIR)
  // ===========================================================================
  void _showCameraView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E), // Fond sombre pour la caméra
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN-TÊTE : Titre et Croix pour fermer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Caméra : ${room.name}", 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context), // Quitte l'affichage caméra
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // L'ÉCRAN DE LA CAMÉRA (Simulé)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icône de caméra au centre
                      const Icon(Icons.play_circle_outline, color: Colors.white24, size: 60),
                      
                      // Badge "EN DIRECT" en haut à droite
                      Positioned(
                        top: 10, right: 10,
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            const Text("EN DIRECT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // LES INFOS EN DESSOUS DE LA CAMÉRA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCamInfoRow(
                      Icons.people, 
                      "Personnes détectées", 
                      room.isOccupied ? "1 personne" : "Aucune"
                    ),
                    const Divider(color: Colors.white12),
                    _buildCamInfoRow(
                      Icons.arrow_downward, 
                      "Température Min", 
                      "${(room.temperature - 2.1).toStringAsFixed(1)}°C" // Donnée simulée
                    ),
                    const Divider(color: Colors.white12),
                    _buildCamInfoRow(
                      Icons.arrow_upward, 
                      "Température Max", 
                      "${(room.temperature + 1.5).toStringAsFixed(1)}°C" // Donnée simulée
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Petit widget pour générer les lignes d'informations sous la caméra proprement
  Widget _buildCamInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white54)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. FENÊTRE DE DÉTAILS CLASSIQUE (Celle qui contient le bouton Supprimer)
  // ===========================================================================
  void _showRoomDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: room.color),
            const SizedBox(width: 10),
            Text(room.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.wifi, "IP ESP32", room.espIp),
            _buildDetailRow(Icons.thermostat, "Temp. Actuelle", "${room.temperature}°C"),
            _buildDetailRow(Icons.history, "Dernière Connue", "${room.lastKnownTemperature}°C"),
            _buildDetailRow(
              room.isOccupied ? Icons.person : Icons.person_outline, 
              "Occupation", 
              room.isOccupied ? "Présence" : "Vide"
            ),
            
            if (room.isFroidAlerte)
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Alerte Température !", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text("SUPPRIMER CETTE PIÈCE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label : ", style: const TextStyle(color: Colors.blueGrey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}