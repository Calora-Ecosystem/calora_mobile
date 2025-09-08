import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ActionsBottomSheet extends StatelessWidget {
  const ActionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.colors.strokeSub,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Amallar",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text("Ma’lumotlarni tozalash"),
            onTap: () {
              Navigator.pop(context);
              // TODO: implement delete action
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text("Ulashish"),
            onTap: () {
              Navigator.pop(context);
              // TODO: implement share action
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text("Ilovani ulash"),
            onTap: () {
              Navigator.pop(context);
              // TODO: implement app share action
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
