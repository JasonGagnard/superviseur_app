import 'dart:convert';
import 'dart:io';

const List<String> _esp32PageSignatures = [
  'Caméra Thermique 32x24',
  'Heatmap Thermique',
  'WebSocketsServer',
  'ws://',
];

bool _looksLikeEsp32Page(String body) {
  return _esp32PageSignatures.any(body.contains);
}

Future<bool> isEsp32Reachable(
  String host, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final trimmedHost = host.trim();
  if (trimmedHost.isEmpty) {
    return false;
  }

  if (await _probeEsp32Port81(trimmedHost, timeout)) {
    return true;
  }

  return _probeEsp32Http(trimmedHost, timeout);
}

Future<String?> discoverEsp32OnLocalNetwork({
  Iterable<String> preferredHosts = const [],
  Iterable<String> extraCandidates = const [],
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  final preferredSet = preferredHosts
      .map((host) => host.trim())
      .where((host) => host.isNotEmpty)
      .toSet();

  final candidateSet = <String>{
    ...preferredSet,
    ...extraCandidates
        .map((host) => host.trim())
        .where((host) => host.isNotEmpty),
  };

  for (final host in candidateSet) {
    if (await isEsp32Reachable(host, timeout: timeout)) {
      return host;
    }
  }

  final prefixes = await _collectIPv4Prefixes();
  for (final prefix in prefixes) {
    final discovered = await _scanPrefixForEsp32(
      prefix,
      timeout: timeout,
      excludedHosts: candidateSet,
    );
    if (discovered != null) {
      return discovered;
    }
  }

  return null;
}

Future<bool> _probeEsp32Http(String host, Duration timeout) async {
  HttpClient? client;
  try {
    client = HttpClient()..connectionTimeout = timeout;
    final request = await client.getUrl(
      Uri(scheme: 'http', host: host, port: 80, path: '/'),
    );
    request.headers.set(HttpHeaders.connectionHeader, 'close');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      return false;
    }

    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return _looksLikeEsp32Page(body);
  } catch (_) {
    return false;
  } finally {
    client?.close(force: true);
  }
}

Future<bool> _probeTcpPort(String host, int port, Duration timeout) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<String>> _collectIPv4Prefixes() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  final prefixes = <String>{};
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (address.type != InternetAddressType.IPv4 ||
          address.isLoopback ||
          address.isLinkLocal) {
        continue;
      }

      final parts = address.address.split('.');
      if (parts.length == 4) {
        prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
      }
    }
  }

  return prefixes.toList();
}

Future<String?> _scanPrefixForEsp32(
  String prefix, {
  required Duration timeout,
  required Set<String> excludedHosts,
}) async {
  final candidates = <String>[];
  for (var hostIndex = 1; hostIndex < 255; hostIndex++) {
    final host = '$prefix.$hostIndex';
    if (!excludedHosts.contains(host)) {
      candidates.add(host);
    }
  }

  const batchSize = 16;
  for (var index = 0; index < candidates.length; index += batchSize) {
    final batch = candidates.sublist(
      index,
      index + batchSize > candidates.length
          ? candidates.length
          : index + batchSize,
    );

    final results = await Future.wait(
      batch.map((host) => _probeCandidateHost(host, timeout)),
    );

    final foundIndex = results.indexWhere((result) => result);
    if (foundIndex != -1) {
      return batch[foundIndex];
    }
  }

  return null;
}

Future<bool> _probeCandidateHost(String host, Duration timeout) async {
  if (await _probeEsp32Port81(host, timeout)) {
    return true;
  }

  return _probeEsp32Http(host, timeout);
}

Future<bool> _probeEsp32Port81(String host, Duration timeout) async {
  try {
    final socket = await Socket.connect(host, 81, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
