import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/selection/Selection.dart';
import 'package:calora/domain/model/selection/selection_type.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:calora/presentation/account/detail/management/account_detail_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/calendar/select/select_calendar_page.dart';
import 'package:calora/presentation/input/single/single_input_page.dart';
import 'package:calora/presentation/selection/single/single_selection_page.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/detail/info/detail_info_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AccountDetailPage extends Managed<AccountDetailManager, AccountDetailState, AccountDetailEffect> {
  AccountDetailPage({super.key});

  @override
  void init(context, manager) {
    manager.getProfileDetail();
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.accountInformation, onBack: () => _back(context)),
      body: _uiBuilder(state, context, manager),
    );
  }

  Widget _uiBuilder(AccountDetailState state, BuildContext context, AccountDetailManager manager) {
    return Loadable(
      loading: state.loading,
      builder: (context) {
        return ListView.separated(
          separatorBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: context.colors.strokeSoft),
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: state.detailInfos?.length ?? 0,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final detailsInfo = state.detailInfos![index];
            return DetailInfoItemBuilder(
              detailInfo: detailsInfo,
              onClickItem: (data) => _openInputManagePage(data, context, manager),
            );
          },
        );
      },
    );
  }

  void _openInputManagePage(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    switch (info.type) {
      case DetailInfoType.activityLevel:
        _openSingleSelectionActivityLevel(info, context, manager);
        break;
      case DetailInfoType.goal:
        _openSingleSelectionGoal(info, context, manager);
        break;
      case DetailInfoType.gender:
        _openSingleSelectionGender(info, context, manager);
        break;
      case DetailInfoType.birthDay:
        _openSelectCalendar(info, context, manager);
        break;
      default:
        _openInputPage(info, context, manager);
        break;
    }
  }

  void _openSingleSelectionActivityLevel(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return ManagerBuilder<AccountDetailState, AccountDetailEffect>(
          manager: manager,
          builder: (context, accountState) {
            return SingleSelectionPage(
              loading: accountState.updatingType == info.type,
              title: Strings.chooseActivityLevel,
              initialSelectedValue: ActivityLevelEnum.fromApi(info.message).displayName,
              selection: Selection(type: SelectionType.activityLevel),
              onSave: (data) {
                manager.updateProfileDetail(info, data.name);
                profileStore.updateProfile(activityLevel: data.name);
                _dismiss(context);
              },
            );
          },
        );
      },
    );
  }

  void _openSingleSelectionGoal(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return ManagerBuilder<AccountDetailState, AccountDetailEffect>(
          manager: manager,
          builder: (context, accountState) {
            return SingleSelectionPage(
              loading: accountState.updatingType == info.type,
              title: Strings.chooseGoal,
              initialSelectedValue: PurposeEnum.fromApi(info.message).displayName,
              selection: Selection(type: SelectionType.goal),
              onSave: (data) {
                manager.updateProfileDetail(info, data.name);
                _dismiss(context);
              },
            );
          },
        );
      },
    );
  }

  void _openSingleSelectionGender(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return ManagerBuilder<AccountDetailState, AccountDetailEffect>(
          manager: manager,
          builder: (context, accountState) {
            return SingleSelectionPage(
              loading: accountState.updatingType == info.type,
              title: Strings.chooseGender,
              initialSelectedValue: Gender.fromApi(info.message).displayName,
              selection: Selection(type: SelectionType.gender),
              onSave: (data) {
                Gender gender = Gender.Male;
                if (data.name == Strings.male)
                  gender = Gender.Male;
                else
                  gender = Gender.Female;
                manager.updateProfileDetail(info, gender.displayName);
                profileStore.updateProfile(gender: gender.toApi());
                _dismiss(context);
              },
            );
          },
        );
      },
    );
  }

  void _openInputPage(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return ManagerBuilder<AccountDetailState, AccountDetailEffect>(
          manager: manager,
          builder: (context, accountState) {
            return SingleInputPage(
              loading: accountState.updatingType == info.type,
              title: info.title,
              metrics: info.metric,
              textInputType: info.currentTextInputType,
              message: info.message,
              onSave: (data) {
                profileStore.updateProfile(
                  name: info.type == DetailInfoType.name ? data : null,
                  weight: info.type == DetailInfoType.weight ? double.tryParse(data) : null,
                  height: info.type == DetailInfoType.height ? double.tryParse(data) : null,
                  targetWeight: info.type == DetailInfoType.targetWeight ? double.tryParse(data) : null,
                );
                manager.updateProfileDetail(info, data);
                _dismiss(context);
              },
            );
          },
        );
      },
    );
  }

  void _openSelectCalendar(DetailInfo info, BuildContext context, AccountDetailManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return ManagerBuilder<AccountDetailState, AccountDetailEffect>(
          manager: manager,
          builder: (context, accountState) {
            return SelectCalendarPage(
              loading: accountState.updatingType == info.type,
              title: info.title,
              selectedDate: info.message,
              onSave: (data) {
                manager.updateProfileDetail(info, data);
                profileStore.updateProfile(birthDay: data);
                _dismiss(context);
              },
            );
          },
        );
      },
    );
  }

  void _dismiss(BuildContext context) => context.router.maybePop();
  void _back(BuildContext context) => context.router.maybePop();
}
