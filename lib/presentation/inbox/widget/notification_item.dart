import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/inbox/widget/notification_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem extends StatefulWidget {
  final model.Notification notification;

  const NotificationItem({super.key, required this.notification});

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  void _onTap(BuildContext context) async {
    if (!widget.notification.hasRead) {
      getIt<NotificationRepo>().markAsRead(widget.notification.id).then((_) {
        setState(() => widget.notification.hasRead = true);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationBottomSheet(notification: widget.notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy  HH:mm');
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.notification.image != null)
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: const Color(0xFFE0E0E0),
                  image: DecorationImage(
                    image: NetworkImage(widget.notification.image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: widget.notification.title.text(16, 20, 500),
                      ),
                      if (!widget.notification.hasRead)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B9D),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      dateFormat
                          .format(widget.notification.sentAt)
                          .text(14, 18, 400)
                          .c(const Color(0xFF9E9E9E)),
                      Strings.moreDetails.text(14, 18, 500).c(const Color(0xFF4FC3F7)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
