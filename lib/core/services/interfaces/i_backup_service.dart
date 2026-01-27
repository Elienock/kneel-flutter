/// Abstract interface for backup services.
/// Handles exporting and importing prayer data.
abstract class IBackupService {
  /// Exports all prayers to CSV format.
  /// Returns the file path of the exported CSV.
  Future<String> exportToCsv();

  /// Exports all prayers to JSON format.
  /// Returns the file path of the exported JSON.
  Future<String> exportToJson();

  /// Imports prayers from a JSON file.
  /// Returns the number of prayers imported.
  Future<int> importFromJson(String filePath);

  /// Gets the last backup timestamp.
  Future<DateTime?> getLastBackupTime();

  /// Shares the backup file using the system share sheet.
  Future<void> shareBackup(String filePath);
}
