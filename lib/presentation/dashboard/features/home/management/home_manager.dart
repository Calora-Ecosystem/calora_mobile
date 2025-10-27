import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {
  final ProfileRepo _profileRepo;

  HomeManager(this._profileRepo) : super(HomeState());

  void getUserInfo() {
    _profileRepo.getProfile().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (profile) {
        emit(state.copyWith(profile: profile, isLoading: false));
        profileStore.clear();
        profileStore.set(profile);
      },
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> requestPedometerPermissions() async {
    await [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.locationWhenInUse,
    ].request();
  }
}
