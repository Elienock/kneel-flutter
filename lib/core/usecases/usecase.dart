import 'package:equatable/equatable.dart';

/// Base class for all use cases in the application.
///
/// [T] is the return type of the use case.
/// [Params] is the type of parameters the use case accepts.
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use this class when a use case doesn't require any parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
