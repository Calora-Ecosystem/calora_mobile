import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DetailInfoItemBuilder extends StatelessWidget {
  final DetailInfo detailInfo;

  final Function(DetailInfo) onClickItem;

  const DetailInfoItemBuilder({
    super.key,
    required this.detailInfo,
    required this.onClickItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      title: detailInfo.title.text(14, 16, 400).c(context.colors.textStrong),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          detailInfo.resultMessage
              .text(14, 16, 400)
              .c(
                detailInfo.isHaveMessage
                    ? context.colors.textStrong
                    : context.colors.textSub,
              ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () => onClickItem(detailInfo),
    );
  }
}
