import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AccountDetailManager
    extends Manager<AccountDetailState, AccountDetailEffect> {
  final ProfileRepo profileRepo;

  AccountDetailManager(this.profileRepo) : super(const AccountDetailState());

  void getProfileDetail() async {
    await profileRepo.getProfileDetail().handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) => emit(state.copyWith(detailInfos: data, loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }
}
