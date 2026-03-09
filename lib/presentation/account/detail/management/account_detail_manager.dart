import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AccountDetailManager
    extends Manager<AccountDetailState, AccountDetailEffect> {
  final ProfileRepo profileRepo;
  final QuestionsRepo questionsRepo;

  AccountDetailManager(this.profileRepo, this.questionsRepo)
      : super(const AccountDetailState());

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

    final profileStoreModel = await profileStore.getProfile();
    
    final questionsRequest = _buildQuestionsRequestFromDetailInfos(
      state.detailInfos!,
      profileStoreModel.physicalActivity,
    );

    await questionsRepo.sendAnswers(questionsRequest).then((_) async {
      // API muvaffaqiyatli bo'lsa, local store-ni ham yangilaymiz
      final profileRequest = _buildProfileRequestFromDetailInfos(
        state.detailInfos!,
      );
      
      double? calculatedBmi;
      if (profileRequest.weight != null && profileRequest.height != null && profileRequest.height! > 0) {
        final heightInMeters = profileRequest.height! / 100;
        calculatedBmi = profileRequest.weight! / (heightInMeters * heightInMeters);
        calculatedBmi = double.parse(calculatedBmi.toStringAsFixed(2));
      }

      await profileStore.updateProfile(
        name: profileRequest.name,
        birthDay: profileRequest.birthDay,
        height: profileRequest.height,
        weight: profileRequest.weight,
        gender: profileRequest.gender,
        goal: profileRequest.goal,
        activityLevel: profileRequest.activityLevel,
        targetWeight: profileRequest.targetWeight,
        bmi: calculatedBmi,
      );

      emit(state.copyWith(updatingType: null));
    }).catchError((error) {
      emit(state.copyWith(updatingType: null));
    });
  }

  QuestionsRequest _buildQuestionsRequestFromDetailInfos(
      List<DetailInfo> infos, String? physicalActivity) {
    String? name;
    String? birthDay;
    double? height;
    double? weight;
    String? gender;
    String? goal;
    String? activityLevel;
    double? targetWeight;

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
        case DetailInfoType.targetWeight:
          targetWeight = double.tryParse(info.message);
          break;
        default:
          break;
      }
    }

    // Purpose mappingni onboarding bilan bir xil qilamiz
    String? purposeApi = goal;
    if (purposeApi == '0' || purposeApi == 'WeightLoss')
      purposeApi = 'WeightLoss';
    else if (purposeApi == '1' || purposeApi == 'SaveCurrent')
      purposeApi = 'SaveCurrent';
    else if (purposeApi == '2' || purposeApi == 'MuscleDevelopment')
      purposeApi = 'MuscleDevelopment';

    final tWeight = (targetWeight ?? 0) == 0 ? (weight ?? 0) : targetWeight;

    double? bmiValue;
    if (weight != null && height != null && height > 0) {
      bmiValue = weight / ((height / 100) * (height / 100));
    }

    return QuestionsRequest(
      name: name,
      gender: gender,
      purpose: purposeApi,
      birthDate: birthDay != null ? DateTime.tryParse(birthDay) : null,
      height: height,
      weight: weight,
      bmi: bmiValue,
      targetWeight: tWeight,
      activityLevel: activityLevel,
      language: 'Uzbek',
      physicalActivity: physicalActivity,
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
    double? targetWeight;

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
        case DetailInfoType.targetWeight:
          targetWeight = double.tryParse(info.message);
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
      targetWeight: (targetWeight ?? 0) == 0 ? weight : targetWeight,
    );
  }
}

