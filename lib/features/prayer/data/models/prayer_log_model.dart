import 'package:hive/hive.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer_session.dart';

part 'prayer_log_model.g.dart';

/// Hive model for tracking individual prayer persistence logs.
/// This tracks how many times a specific prayer has been prayed for.
/// TypeId 4 (after PrayerStatusModel=0, PrayerPriorityModel=1, PrayerModel=2, PrayerSessionModel=3)
@HiveType(typeId: 4)
class PrayerLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String prayerId;

  @HiveField(2)
  final String? userId;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final int? actualDurationSeconds;

  @HiveField(5)
  final DateTime prayedAt;

  @HiveField(6, defaultValue: false)
  final bool isManual;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9, defaultValue: false)
  final bool isSynced;

  PrayerLogModel({
    required this.id,
    required this.prayerId,
    this.userId,
    required this.durationMinutes,
    this.actualDurationSeconds,
    required this.prayedAt,
    this.isManual = false,
    this.notes,
    required this.createdAt,
    this.isSynced = false,
  });

  /// Creates a model from domain entity.
  factory PrayerLogModel.fromEntity(PrayerSession session) {
    return PrayerLogModel(
      id: session.id,
      prayerId: session.prayerId,
      userId: session.userId,
      durationMinutes: session.durationMinutes,
      actualDurationSeconds: session.actualDurationSeconds,
      prayedAt: session.prayedAt,
      isManual: session.isManual,
      notes: session.notes,
      createdAt: session.createdAt,
      isSynced: session.isSynced,
    );
  }

  /// Converts to domain entity.
  PrayerSession toEntity() {
    return PrayerSession(
      id: id,
      prayerId: prayerId,
      userId: userId,
      durationMinutes: durationMinutes,
      actualDurationSeconds: actualDurationSeconds,
      prayedAt: prayedAt,
      isManual: isManual,
      notes: notes,
      createdAt: createdAt,
      isSynced: isSynced,
    );
  }

  /// Creates a copy with updated fields.
  PrayerLogModel copyWith({
    String? id,
    String? prayerId,
    String? userId,
    int? durationMinutes,
    int? actualDurationSeconds,
    DateTime? prayedAt,
    bool? isManual,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return PrayerLogModel(
      id: id ?? this.id,
      prayerId: prayerId ?? this.prayerId,
      userId: userId ?? this.userId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      prayedAt: prayedAt ?? this.prayedAt,
      isManual: isManual ?? this.isManual,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
