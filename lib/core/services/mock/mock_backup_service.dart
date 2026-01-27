import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_backup_service.dart';

/// Mock implementation of [IBackupService] for development and testing.
/// Simulates backup operations without actual file system integration.
@LazySingleton(as: IBackupService)
class MockBackupService implements IBackupService {
  DateTime? _lastBackupTime;

  static const _mockDelay = Duration(milliseconds: 1000);

  @override
  Future<String> exportToCsv() async {
    await Future.delayed(_mockDelay);

    _lastBackupTime = DateTime.now();

    // Return a mock file path
    return '/storage/emulated/0/Download/kneel_prayers_backup.csv';
  }

  @override
  Future<String> exportToJson() async {
    await Future.delayed(_mockDelay);

    _lastBackupTime = DateTime.now();

    // Return a mock file path
    return '/storage/emulated/0/Download/kneel_prayers_backup.json';
  }

  @override
  Future<int> importFromJson(String filePath) async {
    await Future.delayed(_mockDelay);

    // Mock: return a random number of imported prayers
    return 15;
  }

  @override
  Future<DateTime?> getLastBackupTime() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _lastBackupTime;
  }

  @override
  Future<void> shareBackup(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: would use share_plus in real implementation
  }
}
