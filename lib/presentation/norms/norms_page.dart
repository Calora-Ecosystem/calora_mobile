import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/input/single/single_input_page.dart';
import 'package:calora/presentation/norms/management/norms_management.dart';
import 'package:calora/presentation/norms/management/norms_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/detail/info/detail_info_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart' show Managed;

@RoutePage()
class NormsPage extends Managed<NormsManager, NormsState, NormsEffect> {
  const NormsPage({super.key});

  @override
  void init(BuildContext context, NormsManager manager) {
    manager.getDailyNorms();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, NormsManager manager, NormsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.norms),
      body: _uiBuilder(state, context, manager),
    );
  }

  Widget _uiBuilder(NormsState state, BuildContext context, NormsManager manager) {
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
        itemCount: state.dailyNormsList.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final detailsInfo = state.dailyNormsList[index];
          return DetailInfoItemBuilder(
            detailInfo: detailsInfo,
            onClickItem: (data) {
              _openInputPage(data, context, manager);
            },
          );
        },
      );
    }
  }

  void _openInputPage(DetailInfo info, BuildContext context, NormsManager manager) {
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
            manager.updateDailyNorms(info, data);
            _dismiss(context);
          },
        );
      },
    );
  }

  void _dismiss(BuildContext context) {
    Navigator.pop(context);
  }
}
