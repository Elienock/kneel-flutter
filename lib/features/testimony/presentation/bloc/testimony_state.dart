import 'package:equatable/equatable.dart';
import '../../domain/entities/testimony.dart';

/// State for TestimonyCubit.
class TestimonyState extends Equatable {
  final List<Testimony> testimonies;
  final TestimonyStats stats;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const TestimonyState({
    this.testimonies = const [],
    this.stats = const TestimonyStats(),
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  /// Get testimonies filtered by type.
  List<Testimony> byType(TestimonyType type) {
    return testimonies.where((t) => t.type == type).toList();
  }

  /// Get all gratitude entries.
  List<Testimony> get gratitudeEntries => byType(TestimonyType.gratitude);

  /// Get all standalone testimonies.
  List<Testimony> get standaloneTestimonies => byType(TestimonyType.standalone);

  /// Get all answered prayer testimonies.
  List<Testimony> get answeredPrayerTestimonies => byType(TestimonyType.answeredPrayer);

  TestimonyState copyWith({
    List<Testimony>? testimonies,
    TestimonyStats? stats,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return TestimonyState(
      testimonies: testimonies ?? this.testimonies,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        testimonies,
        stats,
        isLoading,
        isSaving,
        error,
        successMessage,
      ];
}
