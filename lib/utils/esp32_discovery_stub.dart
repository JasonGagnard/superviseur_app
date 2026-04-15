Future<bool> isEsp32Reachable(
  String host, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  return false;
}

Future<String?> discoverEsp32OnLocalNetwork({
  Iterable<String> preferredHosts = const [],
  Iterable<String> extraCandidates = const [],
  Duration timeout = const Duration(milliseconds: 600),
}) async {
  return null;
}
