import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/room.dart';
import '../services/backend_api.dart';

class RoomStatsScreen extends StatefulWidget {
  final Room room;
  const RoomStatsScreen({super.key, required this.room});

  @override
  State<RoomStatsScreen> createState() => _RoomStatsScreenState();
}

class _RoomStatsScreenState extends State<RoomStatsScreen> {
  String _timeframe = 'Jour'; // Peut être 'Jour', 'Semaine', 'Mois'
  bool _isLoading = true;
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _loadTemperatures();
  }

  Future<void> _loadTemperatures() async {
    if (widget.room.id == null) {
      setState(() {
        _spots = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rows = await BackendApi.instance.listTemperatures(
        espNodeId: widget.room.id!,
      );
      final now = DateTime.now();
      final filtered = rows.where((row) {
        final measuredAt = DateTime.tryParse(row['measured_at']?.toString() ?? '');
        if (measuredAt == null) {
          return false;
        }
        if (_timeframe == 'Jour') {
          return now.difference(measuredAt).inHours <= 24;
        }
        if (_timeframe == 'Semaine') {
          return now.difference(measuredAt).inDays <= 7;
        }
        return now.difference(measuredAt).inDays <= 30;
      }).toList()
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a['measured_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = DateTime.tryParse(b['measured_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });

      final spots = <FlSpot>[];
      for (var i = 0; i < filtered.length; i++) {
        final temp = (filtered[i]['temperature'] as num?)?.toDouble();
        if (temp != null) {
          spots.add(FlSpot(i.toDouble(), temp));
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _spots = spots;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _spots = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                      onTap: () {
                        setState(() => _timeframe = period);
                        _loadTemperatures();
                      },
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _spots.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune temperature disponible',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : LineChart(
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
                        spots: _spots,
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