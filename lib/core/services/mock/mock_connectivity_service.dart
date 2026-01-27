import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_connectivity_service.dart';

/// Mock implementation of [IConnectivityService] for development and testing.
/// Simulates network connectivity status.
@LazySingleton(as: IConnectivityService)
class MockConnectivityService implements IConnectivityService {
  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  MockConnectivityService() {
    // Emit initial state
    _connectivityController.add(_isOnline);
  }

  @override
  Stream<bool> get isOnline => _connectivityController.stream;

  @override
  Future<bool> checkConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _isOnline;
  }

  /// For testing: simulate going offline
  void simulateOffline() {
    _isOnline = false;
    _connectivityController.add(false);
  }

  /// For testing: simulate coming back online
  void simulateOnline() {
    _isOnline = true;
    _connectivityController.add(true);
  }

  @override
  void dispose() {
    _connectivityController.close();
  }
}
