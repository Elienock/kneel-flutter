/// Abstract interface for connectivity services.
/// Monitors network connectivity status.
abstract class IConnectivityService {
  /// Stream that emits connectivity status changes.
  /// True when online, false when offline.
  Stream<bool> get isOnline;

  /// Checks the current connectivity status.
  /// Returns true if connected to the internet.
  Future<bool> checkConnectivity();

  /// Disposes of any resources used by the service.
  void dispose();
}
