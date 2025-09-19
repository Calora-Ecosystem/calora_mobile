import 'package:calora/domain/repo/profile_repo.dart';
import 'package:calora/presentation/dashboard/features/profile/management/main_profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class MainProfileManager extends Manager<MainProfileState, MainProfileEffect> {
  MainProfileManager(this._repo) : super(const MainProfileState());

  final ProfileRepo _repo;

  Future<void> getProfile() async {
    final profile = await _repo.getProfile();
    emit(state.copyWith(profile: profile));
  }
}
