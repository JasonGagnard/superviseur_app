import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/room.dart';

class RoomStatsScreen extends StatefulWidget {
  final Room room;
  const RoomStatsScreen({super.key, required this.room});

  @override
  State<RoomStatsScreen> createState() => _RoomStatsScreenState();
}

class _RoomStatsScreenState extends State<RoomStatsScreen> {
  String _timeframe = 'Jour'; // Peut être 'Jour', 'Semaine', 'Mois'

  // Générateur de fausses données pour l'exemple
  List<FlSpot> _getDummyData() {
    if (_timeframe == 'Jour') {
      return const [
        FlSpot(0, 18), FlSpot(4, 17.5), FlSpot(8, 20), 
        FlSpot(12, 22), FlSpot(16, 21.5), FlSpot(20, 21), FlSpot(24, 19)
      ];
    } else if (_timeframe == 'Semaine') {
      return const [
        FlSpot(1, 20), FlSpot(2, 21), FlSpot(3, 19), 
        FlSpot(4, 22), FlSpot(5, 22.5), FlSpot(6, 20), FlSpot(7, 21)
      ];
    } else {
      return const [
        FlSpot(1, 19), FlSpot(2, 20.5), FlSpot(3, 21), FlSpot(4, 18.5)
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C1E),
        foregroundColor: Colors.white,
        title: Text("Statistiques - ${widget.room.name}"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- SÉLECTEUR DE PÉRIODE ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Jour', 'Semaine', 'Mois'].map((period) {
                  final isSelected = _timeframe == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _timeframe = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.room.color : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          period,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- LE GRAPHIQUE (SUR FOND BLANC) ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 25, left: 5, top: 25, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: false, 
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300, 
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, 
                          reservedSize: 30, 
                          getTitlesWidget: (val, meta) {
                            return Text(
                              val.toInt().toString(), 
                              style: const TextStyle(
                                color: Colors.black54, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, 
                          reservedSize: 40, 
                          getTitlesWidget: (val, meta) {
                            return Text(
                              "${val.toInt()}°", 
                              style: const TextStyle(
                                color: Colors.black54, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getDummyData(),
                        isCurved: true,
                        color: widget.room.color, 
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: widget.room.color.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}