import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationBottomSheet extends StatelessWidget {
  final model.Notification notification;

  const NotificationBottomSheet({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy  HH:mm');
    return SingleChildScrollView(
      child: Wrap(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.image != null)
                    Container(
                      width: double.infinity,
                      height: 210,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: const Color(0xFFE0E0E0),
                        image: DecorationImage(
                          image: NetworkImage(notification.image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  if (notification.image == null)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        notification.title.text(20, 26, 600).c(const Color(0xFF212121)),
                        const SizedBox(height: 12),
                        dateFormat.format(notification.sentAt).text(14, 18, 400).c(const Color(0xFF9E9E9E)),
                        const SizedBox(height: 20),
                        notification.description.text(14, 22, 400).c(const Color(0xFF757575)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}