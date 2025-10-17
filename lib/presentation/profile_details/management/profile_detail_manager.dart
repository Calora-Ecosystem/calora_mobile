import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'profile_detail_management.dart';

@injectable
class ProfileDetailManager extends Manager<ProfileDetailState, ProfileDetailEffect> {
  final ProfileRepo _repo;
  final AuthStore authStore;
  ProfileDetailManager(this._repo, this.authStore) : super(const ProfileDetailState());

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
    publish(ProfileDetailEffect.showDialog());
  }

  void logOut() {
    authStore.token.set(null);
    authStore.isLogin.set(false);
  }
}
