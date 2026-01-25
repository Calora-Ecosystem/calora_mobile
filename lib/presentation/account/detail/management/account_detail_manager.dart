import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
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
      onError: (error) => emit(state.copyWith(loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }

  void updateProfileDetail(DetailInfo info, String lastResult) async {
    emit(state.copyWith(updatingType: info.type));

    final updatedInfos = state.detailInfos?.map((element) {
      if (element.type == info.type) {
        if (info.type == DetailInfoType.gender) {
          return element.copyWith(
            message: Gender.fromDisplayName(lastResult).toApi(),
          );
        }
        if (info.type == DetailInfoType.goal) {
          return element.copyWith(
            message: PurposeEnum.fromDisplayName(lastResult).toApi(),
          );
        }
        if (info.type == DetailInfoType.activityLevel) {
          return element.copyWith(
            message: ActivityLevelEnum.fromDisplayName(lastResult).toApi(),
          );
        }
        return element.copyWith(message: lastResult);
      }
      return element;
    }).toList();

    emit(state.copyWith(detailInfos: updatedInfos));

    if (state.detailInfos == null) {
      emit(state.copyWith(updatingType: null));
      return;
    }

    final profileRequest = _buildProfileRequestFromDetailInfos(
      state.detailInfos!,
    );

    await profileRepo
        .updateProfile(profileRequest)
        .handle(
          onData: (_) {
            emit(state.copyWith(updatingType: null));
          },
          onError: (error) {
            emit(state.copyWith(updatingType: null));
          },
        );
  }

  ProfileRequest _buildProfileRequestFromDetailInfos(List<DetailInfo> infos) {
    String? name;
    String? birthDay;
    double? height;
    double? weight;
    String? gender;
    String? goal;
    String? activityLevel;

    for (var info in infos) {
      switch (info.type) {
        case DetailInfoType.name:
          name = info.message;
          break;
        case DetailInfoType.birthDay:
          birthDay = info.message;
          break;
        case DetailInfoType.height:
          height = double.tryParse(info.message);
          break;
        case DetailInfoType.weight:
          weight = double.tryParse(info.message);
          break;
        case DetailInfoType.gender:
          gender = info.message;
          break;
        case DetailInfoType.goal:
          goal = info.message;
          break;
        case DetailInfoType.activityLevel:
          activityLevel = info.message;
          break;
        default:
          break;
      }
    }

    return ProfileRequest(
      name: name,
      birthDay: birthDay,
      height: height,
      weight: weight,
      gender: gender,
      goal: goal,
      activityLevel: activityLevel,
    );
  }
}
