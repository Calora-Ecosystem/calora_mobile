import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile.dart';
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
class AccountDetailPage
    extends Managed<AccountDetailManager, AccountDetailState, AccountDetailEffect> {
  final Profile profile;

  AccountDetailPage({super.key, required this.profile});

  @override
  void init(context, manager) {
    manager.getProfileDetail();
  }

  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.accountInformation, onBack: () => _back(context)),
      body: Stack(
        children: [
          _uiBuilder(state, context, manager),
          if (state.saving)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _uiBuilder(AccountDetailState state, BuildContext context, AccountDetailManager manager) {
    if (state.loading) {
      return Loadable(
        builder: (context) {
          return SizedBox();
        },
      );
    } else {
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
            onClickItem: (data) {
              _openInputManagePage(data, context, manager);
            },
          );
        },
      );
    }
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
      case DetailInfoType.metrics:
        _openSingleSelectionMetrics(info, context, manager);
        break;
      case DetailInfoType.birthDay:
        _openSelectCalendar(info, context, manager);
        break;
      default:
        _openInputPage(info, context, manager);
        break;
    }
  }

  void _openSingleSelectionActivityLevel(
    DetailInfo info,
    BuildContext context,
    AccountDetailManager manager,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return SingleSelectionPage(
          title: Strings.chooseActivityLevel,
          selection: Selection(type: SelectionType.activityLevel),
          onSave: (data) {
            manager.updateProfileDetail(info, data.name);
            _dismiss(context);
          },
        );
      },
    );
  }

  void _openSingleSelectionGoal(
    DetailInfo info,
    BuildContext context,
    AccountDetailManager manager,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return SingleSelectionPage(
          title: Strings.chooseGoal,
          selection: Selection(type: SelectionType.goal),
          onSave: (data) {
            manager.updateProfileDetail(info, data.name);
            _dismiss(context);
          },
        );
      },
    );
  }

  void _openSingleSelectionMetrics(
    DetailInfo info,
    BuildContext context,
    AccountDetailManager manager,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return SingleSelectionPage(
          title: Strings.chooseMetrics,
          selection: Selection(type: SelectionType.metrics),
          onSave: (data) {
            manager.updateProfileDetail(info, data.name);
            _dismiss(context);
          },
        );
      },
    );
  }

  void _openSingleSelectionGender(
    DetailInfo info,
    BuildContext context,
    AccountDetailManager manager,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return SingleSelectionPage(
          title: Strings.chooseGender,
          selection: Selection(type: SelectionType.gender),
          onSave: (data) {
            manager.updateProfileDetail(info, data.name);
            _dismiss(context);
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
        return SingleInputPage(
          title: info.title,
          metrics: info.metric,
          textInputType: info.currentTextInputType,
          message: info.message,
          onSave: (data) {
            manager.updateProfileDetail(info, data);
            _dismiss(context);
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
        return SelectCalendarPage(
          title: info.title,
          selectedDate: info.message,
          onSave: (data) {
            manager.updateProfileDetail(info, data);
            _dismiss(context);
          },
        );
      },
    );
  }

  void _dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _back(BuildContext context) {
    context.router.pop();
  }
}
