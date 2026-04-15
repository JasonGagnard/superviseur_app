import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ThermalFrameStats {
  final double currentTemperature;
  final double minTemperature;
  final double maxTemperature;

  const ThermalFrameStats({
    required this.currentTemperature,
    required this.minTemperature,
    required this.maxTemperature,
  });
}

class LiveThermalStream extends StatefulWidget {
  final String streamUrl;
  final Color accentColor;
  final ValueChanged<ThermalFrameStats>? onStats;

  const LiveThermalStream({
    super.key,
    required this.streamUrl,
    required this.accentColor,
    this.onStats,
  });

  @override
  State<LiveThermalStream> createState() => _LiveThermalStreamState();
}

class _LiveThermalStreamState extends State<LiveThermalStream> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  List<double>? _frame;
  double? _minTemp;
  double? _maxTemp;
  bool _connecting = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant LiveThermalStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _resetConnection();
      _connect();
    }
  }

  @override
  void dispose() {
    _resetConnection();
    super.dispose();
  }

  Uri? _resolveWebSocketUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.contains('://') ? trimmed : 'ws://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }

    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      'ws' => 'ws',
      'wss' => 'wss',
      _ => 'ws',
    };

    final path =
        (uri.path.isEmpty ||
            uri.path == '/' ||
            uri.path == '/81' ||
            uri.path == '81')
        ? '/'
        : uri.path;

    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : 81,
      path: path,
      query: uri.query,
    );
  }

  void _connect() {
    final uri = _resolveWebSocketUri(widget.streamUrl);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connecting = false;
        _errorText = 'URL WebSocket invalide';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _connecting = true;
      _errorText = null;
    });

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: true,
      );
    } catch (error) {
      _scheduleReconnect('Impossible de se connecter au flux: $error');
    }
  }

  void _handleMessage(dynamic event) {
    Uint8List? bytes;

    if (event is Uint8List) {
      bytes = event;
    } else if (event is List<int>) {
      bytes = Uint8List.fromList(event);
    } else if (event is ByteBuffer) {
      bytes = event.asUint8List();
    }

    if (bytes == null || bytes.lengthInBytes < 768 * 4) {
      return;
    }

    final byteData = ByteData.sublistView(bytes);
    final frame = List<double>.filled(768, 0.0, growable: false);
    double minTemp = double.infinity;
    double maxTemp = -double.infinity;

    for (var index = 0; index < 768; index++) {
      final temperature = byteData.getFloat32(index * 4, Endian.little);
      frame[index] = temperature;
      if (temperature < minTemp) minTemp = temperature;
      if (temperature > maxTemp) maxTemp = temperature;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _frame = frame;
      _minTemp = minTemp;
      _maxTemp = maxTemp;
      _connecting = false;
      _errorText = null;
    });

    widget.onStats?.call(
      ThermalFrameStats(
        currentTemperature: frame[frame.length ~/ 2],
        minTemperature: minTemp,
        maxTemperature: maxTemp,
      ),
    );
  }

  void _handleError(Object error) {
    _scheduleReconnect('Connexion WebSocket impossible: $error');
  }

  void _handleDone() {
    _scheduleReconnect('Connexion WebSocket fermée');
  }

  void _scheduleReconnect(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _connecting = false;
      _errorText = message;
    });

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      _resetConnection();
      _connect();
    });
  }

  void _resetConnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  String get _connectionLabel {
    if (_frame != null) {
      return 'Connecté en Temps Réel';
    }

    if (_connecting) {
      return 'Connexion WebSocket...';
    }

    return _errorText ?? 'Déconnecté';
  }

  Color get _connectionColor {
    if (_frame != null) {
      return Colors.greenAccent;
    }

    if (_connecting) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streamUrl.isEmpty) {
      return _buildMessage(
        icon: Icons.wifi_off,
        title: 'Flux absent',
        subtitle: 'Configure l\'URL du WebSocket thermique.',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_frame != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _ThermalHeatmapPainter(
                frame: _frame!,
                minTemp: _minTemp ?? 0.0,
                maxTemp: _maxTemp ?? 1.0,
              ),
            ),
          )
        else
          Positioned.fill(
            child: _buildMessage(
              icon: _connecting ? Icons.sync : Icons.error_outline,
              title: _connecting ? 'Connexion au flux' : 'Flux indisponible',
              subtitle: _connecting
                  ? 'Attente des données du WebSocket...'
                  : (_errorText ?? 'Aucune trame reçue.'),
            ),
          ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: widget.accentColor.withValues(alpha: 0.9),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThermalHeatmapPainter extends CustomPainter {
  final List<double> frame;
  final double minTemp;
  final double maxTemp;

  const _ThermalHeatmapPainter({
    required this.frame,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.length != 768) {
      return;
    }

    const columns = 32;
    const rows = 24;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    final paint = Paint()..style = PaintingStyle.fill;
    final range = (maxTemp - minTemp).abs() < 0.001 ? 1.0 : (maxTemp - minTemp);

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final temperature = frame[row * columns + column];
        final normalized = ((temperature - minTemp) / range).clamp(0.0, 1.0);
        final hue = (1 - normalized) * 240;
        paint.color = HSLColor.fromAHSL(1, hue, 1, 0.5).toColor();
        canvas.drawRect(
          Rect.fromLTWH(
            column * cellWidth,
            row * cellHeight,
            cellWidth + 0.5,
            cellHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ThermalHeatmapPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.minTemp != minTemp ||
        oldDelegate.maxTemp != maxTemp;
  }
}
