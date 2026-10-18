import 'dart:async';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/profile_details/management/profile_detail_management.dart';

@injectable
class ProfileDetailManager
    extends Manager<ProfileDetailState, ProfileDetailEffect> {
  final ProfileRepo _repo;
  final AuthStore authStore;
  final CommonStore _commonStore;
  ProfileDetailManager(this._repo, this.authStore, this._commonStore)
    : super(const ProfileDetailState());

  void logOutDialog() {
    publish(ProfileDetailEffect.showDialog());
  }

  void logOut() {
    _repo.logOut().handle(
      onStart: () {},
      onDone: () {
        profileStore.clear();
        authStore.token.set(null);
        _commonStore.isQuestionaryFinished.set(false);
        unawaited(FacebookAnalyticsService.instance.clearUser());
        unawaited(getIt<StepCounterService>().stop());
      },
      onError: (e) {},
    );
  }

  void deleteAccountDialog() {
    publish(ProfileDetailEffect.showDeleteAccountDialog());
  }

  Future<void> deleteAccount(String userId) async {
    if (state.isDeletingAccount) return;
    emit(state.copyWith(isDeletingAccount: true));
    try {
      await _repo.deleteAccount(userId);
      profileStore.clear();
      authStore.token.set(null);
      _commonStore.isQuestionaryFinished.set(false);
      unawaited(FacebookAnalyticsService.instance.clearUser());
      unawaited(getIt<StepCounterService>().stop());
      publish(ProfileDetailEffect.accountDeleted());
    } catch (_) {
      publish(ProfileDetailEffect.deleteAccountFailed());
    } finally {
      emit(state.copyWith(isDeletingAccount: false));
    }
  }
}
