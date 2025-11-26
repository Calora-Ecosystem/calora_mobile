import 'dart:io';

import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogFilesPage extends StatelessWidget {
  const LogFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.yellow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('log_files'.tr()),
            ),
          ),
          const SizedBox(height: 16),
          Divider(),
          FutureBuilder<List<File>>(
            future: getLogFiles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading files'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No log files found'));
              } else {
                final logFiles = snapshot.data!;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: logFiles.length,
                    itemBuilder: (context, index) {
                      final file = logFiles[index];
                      final fullFileName = file.path.split('/').last;
                      final fileName = fullFileName.replaceFirst(
                        'network_logs_',
                        '',
                      );

                      return ListTile(
                        title: Text(fileName),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            _shareFile(file);
                          },
                        ),
                        onTap: () {
                          // Add your logic here to handle file selection, e.g., view file content
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: "Log file");
  }

  Future<List<File>> getLogFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final logFiles = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.contains('network_logs_') ||
              file.path.contains('local_logger_'),
        )
        .toList();
    return logFiles;
  }
}
