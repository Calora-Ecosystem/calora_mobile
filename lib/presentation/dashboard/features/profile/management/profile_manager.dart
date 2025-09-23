import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ProfileManager extends Manager<ProfileState, ProfileEffect> {
  ProfileManager(this._repo) : super(const ProfileState());

  final ProfileRepo _repo;

  Future<void> getProfile() async {
    final profile = await _repo.getProfile();
    emit(state.copyWith(profile: profile));
  }
}
