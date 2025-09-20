import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/profile/features/profile_page/management/profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ProfileManager extends Manager<ProfileState, ProfileEffect> {
  final ProfileRepo _repo;
  ProfileManager(this._repo) : super(const ProfileState());

  void onAppleHealthTap() {
    emit(state.copyWith(isAppleHealthSelected: true));
  }

  void onSamsungHealthTap() {
    emit(state.copyWith(isSamsungHealthSelected: true));
  }

  void onGarminTap() {
    emit(state.copyWith(isGarminSelected: true));
  }

  void onGoogleFitTap() {
    emit(state.copyWith(isGoogleFitSelected: true));
  }

  void logOutDialog() {
    publish(ProfileEffect.showDialog());
  }

  void logOut() {
    _repo.logout();
  }
}
