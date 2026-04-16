import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class ConsumptionSimulatorScreen extends StatefulWidget {
  const ConsumptionSimulatorScreen({super.key});

  @override
  State<ConsumptionSimulatorScreen> createState() => _ConsumptionSimulatorScreenState();
}

class _ConsumptionSimulatorScreenState extends State<ConsumptionSimulatorScreen> {
  double _surface = 80.0;
  double _tempCible = 20.0;
  String _isolation = "Moyenne (DPE D/E)";

  final double _tempBase = 19.0;
  final double _prixKwh = 0.25;
  final Map<String, double> _isolationRatios = {
    "Mauvaise (DPE G/F)": 180.0,
    "Moyenne (DPE D/E)": 110.0,
    "Excellente (BBC)": 50.0,
  };

  double _calculateImpact() {
    double ratio = _isolationRatios[_isolation] ?? 110.0;
    double consoBaseAn = _surface * ratio;
    double diffTemp = _tempCible - _tempBase;
    double facteurImpact = 1 + (0.07 * diffTemp);
    double nouvelleConso = consoBaseAn * facteurImpact;
    return (nouvelleConso - consoBaseAn) * _prixKwh;
  }

  Color _getHouseColor() {
    if (_tempCible < 17.0) return Colors.blue;
    if (_tempCible > 21.0) return Colors.red;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (_tempCible < 17.0) return Icons.ac_unit;
    if (_tempCible > 21.0) return Icons.local_fire_department;
    return Icons.check_circle;
  }

  String _getStatusText() {
    if (_tempCible < 17.0) return "Risque pour le foyer";
    if (_tempCible > 21.0) return "Surchauffe / Surcoût";
    return "Confort & Économie";
  }

  void _resetValues() {
    setState(() {
      _surface = 80.0;
      _tempCible = 20.0;
      _isolation = "Moyenne (DPE D/E)";
    });
  }

  @override
  Widget build(BuildContext context) {
    double impact = _calculateImpact();
    bool isSaving = impact <= 0;
    Color currentColor = _getHouseColor();

    return Scaffold(
      backgroundColor: Colors.white, // <-- FOND BLANC
      appBar: AppBar(
        title: const Text("Impact Foyer"),
        backgroundColor: currentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. LA MAISON DYNAMIQUE
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const Icon(Icons.home_rounded, size: 140, color: Colors.white),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(_getStatusIcon(), color: currentColor, size: 35),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(_getStatusText(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSaving ? "Économie : ${impact.abs().toStringAsFixed(0)} € / an" : "Surcoût : +${impact.toStringAsFixed(0)} € / an",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 2. LES ROUES
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              child: Row(
                children: [
                  // --- ROUE TEMPÉRATURE (INVERSÉE) ---
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Température", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 15),
                        SleekCircularSlider(
                          min: 14, max: 26, initialValue: _tempCible,
                          appearance: CircularSliderAppearance(
                            size: 140,
                            customWidths: CustomSliderWidths(trackWidth: 8, progressBarWidth: 12, handlerSize: 10),
                            customColors: CustomSliderColors(
                              trackColor: Colors.black12,
                              // COULEURS INVERSÉES : Rouge -> Vert -> Bleu
                              progressBarColors: [Colors.red, Colors.green, Colors.blue], 
                              dotColor: currentColor,
                            ),
                            infoProperties: InfoProperties(
                              mainLabelStyle: TextStyle(color: currentColor, fontSize: 26, fontWeight: FontWeight.bold),
                              modifier: (double value) => '${value.toStringAsFixed(1)}°',
                            ),
                          ),
                          onChange: (double value) => setState(() => _tempCible = value),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- ROUE SURFACE ---
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Surface", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 15),
                        SleekCircularSlider(
                          min: 20, max: 250, initialValue: _surface,
                          appearance: CircularSliderAppearance(
                            size: 140,
                            customWidths: CustomSliderWidths(trackWidth: 8, progressBarWidth: 12, handlerSize: 10),
                            customColors: CustomSliderColors(
                              trackColor: Colors.black12,
                              progressBarColors: [Colors.blueGrey.shade200, Colors.blueGrey.shade600],
                              dotColor: Colors.blueGrey,
                            ),
                            infoProperties: InfoProperties(
                              mainLabelStyle: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold),
                              modifier: (double value) => '${value.toInt()} m²',
                            ),
                          ),
                          onChange: (double value) => setState(() => _surface = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. ISOLATION ET RESET
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _isolation,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Isolation de la maison",
                        labelStyle: const TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: currentColor)),
                      ),
                      items: _isolationRatios.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (v) => setState(() => _isolation = v!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 28),
                      onPressed: _resetValues,
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "* Règle ADEME : 1°C = 7% de consommation.\nCalcul basé sur une référence à 19°C et 0,25€/kWh.",
                style: TextStyle(fontSize: 11, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}