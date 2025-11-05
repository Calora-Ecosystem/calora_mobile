import 'package:calora/common/base/profile_store.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ProfileManager extends Manager<ProfileState, ProfileEffect> {
  ProfileManager() : super(const ProfileState());

  Future<void> getProfile() async {
    final profile = await profileStore.getProfile();
    emit(state.copyWith(profile: profile));
  }
}
