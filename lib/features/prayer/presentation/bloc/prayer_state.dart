import 'package:equatable/equatable.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

/// Base class for all prayer states.
sealed class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action is taken.
final class PrayerInitial extends PrayerState {
  const PrayerInitial();
}

/// State while prayers are being loaded or an operation is in progress.
final class PrayerLoading extends PrayerState {
  const PrayerLoading();
}

/// State when prayers have been successfully loaded.
final class PrayerLoaded extends PrayerState {
  final List<Prayer> prayers;
  final String? successMessage;

  const PrayerLoaded(this.prayers, {this.successMessage});

  PrayerLoaded copyWith({
    List<Prayer>? prayers,
    String? successMessage,
  }) {
    return PrayerLoaded(
      prayers ?? this.prayers,
      successMessage: successMessage,
    );
  }

  /// Clears the success message.
  PrayerLoaded clearMessage() => PrayerLoaded(prayers);

  @override
  List<Object?> get props => [prayers, successMessage];
}

/// State when an error has occurred.
final class PrayerError extends PrayerState {
  final String message;

  const PrayerError(this.message);

  @override
  List<Object?> get props => [message];
}
