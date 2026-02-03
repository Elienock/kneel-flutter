/// Hall of Faith Feature
///
/// A beautiful gallery for answered prayers and testimonies.
/// Features a masonry grid layout with gold accents celebrating each victory.
///
/// Usage:
/// ```dart
/// // Navigate to the Hall of Faith
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const HallOfFaithPage(),
/// ));
///
/// // Show celebration when prayer is answered
/// showGeneralDialog(
///   context: context,
///   pageBuilder: (_, __, ___) => HallOfFaithCelebration(
///     prayer: prayer,
///     onComplete: () => Navigator.pop(context),
///   ),
/// );
/// ```
library hall_of_faith;

export 'presentation/pages/hall_of_faith_page.dart'
    show HallOfFaithPage, HallOfFaithCelebration, HallOfFaithContent;
export 'presentation/widgets/testimony_card.dart';
export 'presentation/widgets/testimony_detail_view.dart';
