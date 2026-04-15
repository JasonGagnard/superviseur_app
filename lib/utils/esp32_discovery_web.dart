import 'dart:async';

// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> isEsp32Reachable(
  String host, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final trimmedHost = host.trim();
  if (trimmedHost.isEmpty) {
    return false;
  }

  return _probeWebSocket(trimmedHost, timeout);
}

Future<String?> discoverEsp32OnLocalNetwork({
  Iterable<String> preferredHosts = const [],
  Iterable<String> extraCandidates = const [],
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  final candidates = <String>{
    ...preferredHosts
        .map((host) => host.trim())
        .where((host) => host.isNotEmpty),
    ...extraCandidates
        .map((host) => host.trim())
        .where((host) => host.isNotEmpty),
  };

  for (final host in candidates) {
    if (await isEsp32Reachable(host, timeout: timeout)) {
      return host;
    }
  }

  return null;
}

Future<bool> _probeWebSocket(String host, Duration timeout) async {
  final uri = Uri(scheme: 'ws', host: host, port: 81, path: '/');
  html.WebSocket? socket;
  final completer = Completer<bool>();
  Timer? timer;

  try {
    socket = html.WebSocket(uri.toString());
    socket.binaryType = 'arraybuffer';

    socket.onOpen.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });
    socket.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    socket.onClose.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final result = await completer.future;
    return result;
  } catch (_) {
    return false;
  } finally {
    timer?.cancel();
    socket?.close();
  }
}
