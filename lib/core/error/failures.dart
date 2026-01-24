import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Failure related to local cache operations.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache operation failed', super.code});
}

/// Failure related to server/network operations.
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred', super.code});
}

/// Failure related to invalid input or validation.
class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation failed', super.code});
}
