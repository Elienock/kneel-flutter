/// Base exception for the application.
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception thrown when a cache operation fails.
class CacheException extends AppException {
  const CacheException({super.message = 'Cache operation failed', super.code});
}

/// Exception thrown when a server operation fails.
class ServerException extends AppException {
  const ServerException({super.message = 'Server error occurred', super.code});
}

/// Exception thrown when requested data is not found.
class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Resource not found', super.code});
}
