/// Pulpit Mode Feature
///
/// A full-screen prayer leadership tool for leading congregational
/// prayer sessions from the pulpit/stage.
///
/// Features:
/// - Create prayer groups with multiple prayer points
/// - Add scripture references to each point
/// - Auto-advance timer or manual control
/// - Reorderable prayer points
/// - Save groups for reuse
///
/// Usage:
/// ```dart
/// // Navigate to pulpit groups page
/// Navigator.push(context, MaterialPageRoute(
///   builder: (ctx) => BlocProvider(
///     create: (_) => PulpitCubit()..loadGroups(),
///     child: const PulpitGroupsPage(),
///   ),
/// ));
/// ```
library pulpit;

export 'domain/entities/pulpit_prayer_group.dart';
export 'data/repositories/pulpit_repository.dart';
export 'presentation/bloc/pulpit_cubit.dart';
export 'presentation/bloc/pulpit_state.dart';
export 'presentation/pages/pulpit_groups_page.dart';
export 'presentation/pages/pulpit_group_editor_page.dart';
export 'presentation/pages/pulpit_session_page.dart';
export 'presentation/widgets/add_prayer_point_sheet.dart';
