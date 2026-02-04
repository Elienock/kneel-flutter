import '../entities/testimony.dart';

/// Interface for testimony data operations.
abstract class ITestimonyRepository {
  /// Create a new testimony entry.
  Future<Testimony> createTestimony({
    required TestimonyType type,
    required String title,
    String? story,
    String? prayerId,
    String? prayerTitle,
    int prayerCount = 0,
    int? daysToAnswer,
    DateTime? eventDate,
    bool isPublic = false,
    String? imageUrl,
    GratitudeCategory? category,
  });

  /// Get all testimonies for the current user.
  Future<List<Testimony>> getTestimonies({int limit = 100});

  /// Get testimonies by type.
  Future<List<Testimony>> getTestimoniesByType(TestimonyType type, {int limit = 50});

  /// Get a single testimony by ID.
  Future<Testimony?> getTestimonyById(String id);

  /// Update a testimony.
  Future<Testimony> updateTestimony(Testimony testimony);

  /// Update testimony privacy.
  Future<void> updatePrivacy(String id, bool isPublic);

  /// Delete a testimony.
  Future<void> deleteTestimony(String id);

  /// Get public testimonies from all users (for community feed).
  Future<List<Testimony>> getPublicTestimonies({int limit = 50});

  /// Get testimony stats for current user.
  Future<TestimonyStats> getStats();

  /// Stream of testimonies (real-time updates).
  Stream<List<Testimony>> watchTestimonies({int limit = 50});

  /// Stream of stats.
  Stream<TestimonyStats> watchStats();

  /// Celebrate a public testimony (like/praise).
  Future<void> celebrateTestimony(String id);
}
