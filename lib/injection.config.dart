// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:hive_flutter/hive_flutter.dart' as _i986;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

import 'core/di/register_module.dart' as _i854;
import 'core/services/impl/biometric_service.dart' as _i292;
import 'core/services/impl/firebase_auth_service.dart' as _i92;
import 'core/services/impl/supabase_profile_service.dart' as _i320;
import 'core/services/interfaces/i_auth_service.dart' as _i812;
import 'core/services/interfaces/i_backup_service.dart' as _i336;
import 'core/services/interfaces/i_biometric_service.dart' as _i869;
import 'core/services/interfaces/i_connectivity_service.dart' as _i577;
import 'core/services/interfaces/i_notification_service.dart' as _i615;
import 'core/services/interfaces/i_profile_service.dart' as _i630;
import 'core/services/mock/mock_backup_service.dart' as _i511;
import 'core/services/mock/mock_connectivity_service.dart' as _i679;
import 'core/services/mock/mock_notification_service.dart' as _i974;
import 'features/auth/presentation/bloc/auth_cubit.dart' as _i538;
import 'features/prayer/data/datasources/prayer_local_data_source.dart'
    as _i610;
import 'features/prayer/data/models/prayer_model.dart' as _i36;
import 'features/prayer/data/models/prayer_session_model.dart' as _i739;
import 'features/prayer/data/repositories/prayer_repository_impl.dart' as _i358;
import 'features/prayer/domain/repositories/i_prayer_repository.dart' as _i348;
import 'features/prayer/domain/usecases/add_prayer.dart' as _i540;
import 'features/prayer/domain/usecases/delete_prayer.dart' as _i584;
import 'features/prayer/domain/usecases/get_prayers.dart' as _i460;
import 'features/prayer/presentation/bloc/prayer_cubit.dart' as _i1045;
import 'features/prayer/presentation/bloc/session_cubit.dart' as _i541;
import 'features/profile/presentation/bloc/profile_cubit.dart' as _i817;
import 'features/sermon/data/models/sermon_note_model.dart' as _i797;
import 'features/sermon/data/repositories/supabase_sermon_repository.dart'
    as _i264;
import 'features/sermon/domain/repositories/i_sermon_repository.dart' as _i705;
import 'features/sermon/presentation/bloc/sermon_cubit.dart' as _i269;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    await gh.lazySingletonAsync<_i986.Box<_i36.PrayerModel>>(
      () => registerModule.prayerBox,
      preResolve: true,
    );
    await gh.lazySingletonAsync<_i986.Box<_i739.PrayerSessionModel>>(
      () => registerModule.sessionBox,
      preResolve: true,
    );
    gh.lazySingleton<_i869.IBiometricService>(() => _i292.BiometricService());
    gh.lazySingleton<_i610.PrayerLocalDataSource>(() =>
        _i610.PrayerLocalDataSourceImpl(gh<_i979.Box<_i36.PrayerModel>>()));
    gh.lazySingleton<_i630.IProfileService>(
        () => _i320.SupabaseProfileService());
    gh.lazySingleton<_i615.INotificationService>(
        () => _i974.MockNotificationService());
    gh.factory<_i817.ProfileCubit>(() => _i817.ProfileCubit(
          gh<_i630.IProfileService>(),
          gh<_i812.IAuthService>(),
        ));
    await gh.lazySingletonAsync<_i986.Box<_i797.SermonNoteModel>>(
      () => registerModule.sermonBox,
      instanceName: 'sermonBox',
      preResolve: true,
    );
    gh.factory<_i541.SessionCubit>(() => _i541.SessionCubit(
          gh<_i979.Box<_i739.PrayerSessionModel>>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i577.IConnectivityService>(
        () => _i679.MockConnectivityService());
    gh.lazySingleton<_i348.IPrayerRepository>(
        () => _i358.PrayerRepositoryImpl(gh<_i610.PrayerLocalDataSource>()));
    gh.lazySingleton<_i705.ISermonRepository>(
        () => _i264.SupabaseSermonRepository());
    gh.lazySingleton<_i336.IBackupService>(() => _i511.MockBackupService());
    gh.lazySingleton<_i584.DeletePrayer>(
        () => _i584.DeletePrayer(gh<_i348.IPrayerRepository>()));
    gh.lazySingleton<_i460.GetPrayers>(
        () => _i460.GetPrayers(gh<_i348.IPrayerRepository>()));
    gh.lazySingleton<_i812.IAuthService>(() => _i92.FirebaseAuthService(
          gh<_i869.IBiometricService>(),
          gh<_i630.IProfileService>(),
        ));
    gh.lazySingleton<_i540.AddPrayer>(() => _i540.AddPrayer(
          gh<_i348.IPrayerRepository>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i269.SermonCubit>(
        () => _i269.SermonCubit(gh<_i705.ISermonRepository>()));
    gh.factory<_i538.AuthCubit>(
        () => _i538.AuthCubit(gh<_i812.IAuthService>()));
    gh.factory<_i1045.PrayerCubit>(() => _i1045.PrayerCubit(
          gh<_i460.GetPrayers>(),
          gh<_i540.AddPrayer>(),
          gh<_i584.DeletePrayer>(),
          gh<_i348.IPrayerRepository>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i854.RegisterModule {}
