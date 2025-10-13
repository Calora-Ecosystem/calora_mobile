import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ProfileManager extends Manager<ProfileState, ProfileEffect> {
  ProfileManager(this._repo) : super(const ProfileState());

  final ProfileRepo _repo;

  Future<void> getProfile() async {
    await _repo.getProfile().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (profile) => emit(state.copyWith(profile: profile, isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }
}
