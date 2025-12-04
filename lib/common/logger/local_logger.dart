import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalLogger {
  static final LocalLogger _instance = LocalLogger._internal();

  factory LocalLogger() => _instance;

  LocalLogger._internal();

  File? _logFile;
  final String _filePrefix = 'local_logger_';

  Future<File> get _file async {
    if (_logFile != null) return _logFile!;
    await _initLogFile();
    return _logFile!;
  }

  Future<void> _initLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final currentDate = DateTime.now().toIso8601String().split('T').first;
    final path = '${directory.path}/$_filePrefix$currentDate.txt';
    _logFile = File(path);

    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }
  }

  Future<void> writeToFile(String message) async {
    try {
      final file = await _file;
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString(
        'Time: $timestamp\n$message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<File>> getLogFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = <File>[];
    await for (var entity in directory.list()) {
      if (entity is File && entity.path.contains(_filePrefix)) {
        files.add(entity);
      }
    }
    return files;
  }
}
