import '../services/backend_api.dart';

class AppLogger {
  static Future<void> log(
    String username,
    String message, {
    String logType = 'user',
    String? concernedColumn,
  }) async {
    try {
      await BackendApi.instance.createLog(
        username: username,
        logType: logType,
        actionLog: message,
        concernedColumn: concernedColumn,
      );
    } catch (_) {
      // Logging should never block UI interactions.
    }
  }
}