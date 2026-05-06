import 'dart:async';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ProfileManager extends Manager<ProfileState, ProfileEffect> {
  ProfileManager() : super(const ProfileState());

  StreamSubscription<ProfileRequest>? _profileSub;
  bool _initialized = false;

  /// Subscribes to the global profile store so the page reacts to any
  /// downstream update (account detail edits, weight log, target change, …).
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _profileSub = profileStore.stream().listen((profile) {
      emit(
        state.copyWith(
          profile: profile,
          showBmiProgress: _shouldShowBmiProgress(profile),
        ),
      );
    });
  }

  /// Show the progress section only when the user has a real numeric
  /// weight goal that differs from where they started — the `purpose`
  /// label alone isn't trustworthy (see weight-update bug).
  bool _shouldShowBmiProgress(ProfileRequest profile) {
    final goal = (profile.goal ?? '').trim();
    if (goal == 'SaveCurrent') return false;

    final entry = profile.entryWeight;
    final target = profile.targetWeight;
    if (target == null || target <= 0) return false;
    if (entry == null || entry <= 0) return false;
    return entry != target;
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    return super.close();
  }
}
