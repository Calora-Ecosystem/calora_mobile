import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: detailInfo.title.text(14, 16, 400).c(context.colors.textStrong),
      trailing: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: detailInfo.resultMessage
                  .text(14, 16, 400)
                  .c(detailInfo.isHaveMessage ? context.colors.textStrong : context.colors.textSub)
                  .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Assets.icons.icForward.svg(colorFilter: ColorFilter.mode(context.colors.black, BlendMode.srcIn)),
          ],
        ),
      ),
      onTap: () => onClickItem(detailInfo),
    );
  }
}
