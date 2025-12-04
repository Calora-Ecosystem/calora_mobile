import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

@lazySingleton
class LoggingInterceptor extends Interceptor {
  late File logFile;

  LoggingInterceptor() {
    _initLogFile();
  }

  Future<void> _initLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final currentDate = DateTime.now().toIso8601String().split('T').first;
    final path = '${directory.path}/network_logs_$currentDate.txt';
    logFile = File(path);
    if (!await logFile.exists()) {
      await logFile.create();
    }
    _cleanupOldLogs(directory);
  }

  Future<void> _cleanupOldLogs(Directory directory) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final dateFormat = DateFormat('yyyy-MM-dd');

      await for (var entity in directory.list()) {
        if (entity is File && entity.path.contains('network_logs_')) {
          try {
            final fileName = entity.path.split('/').last;
            final fileDateStr = fileName.split('_').last.split('.').first;

            // Parse the date - this might throw FormatException
            final fileDate = dateFormat.parse(fileDateStr);

            if (fileDate.isBefore(sevenDaysAgo)) {
              // Check if file still exists before attempting to delete
              if (await entity.exists()) {
                await entity.delete();
              }
            }
          } on FormatException catch (e) {
            // Skip files with invalid date format
            log('Skipping file with invalid date format: ${entity.path}');
          } on PathNotFoundException catch (e) {
            // File was already deleted or doesn't exist - safe to ignore
            log('File no longer exists: ${entity.path}');
          } catch (e) {
            // Log other errors but continue processing other files
            log('Error processing file ${entity.path}: $e');
          }
        }
      }
    } catch (exception) {
      log('Error during log cleanup: $exception');
    }
  }

  Future<void> _writeToFile(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    await logFile.writeAsString('Time: $timestamp\n$message\n',
        mode: FileMode.append);
  }

  String _convertToJson(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return 'Error converting to JSON: $e';
    }
  }

  String _formDataToReadable(FormData formData) {
    final buffer = StringBuffer();

    buffer.writeln('FormData fields:');
    for (var field in formData.fields) {
      final value = field.value;

      if (field.key.toLowerCase().contains('photo') ||
          field.key.toLowerCase().contains('image') ||
          value.length > 500) {
        buffer.writeln(
            '  ${field.key}: <base64 hidden, length: ${value.length}>');
      } else {
        buffer.writeln('  ${field.key}: $value');
      }
    }

    buffer.writeln('FormData files:');
    for (var fileMap in formData.files) {
      final key = fileMap.key;
      final file = fileMap.value;
      final filename = file.filename ?? 'unknown';
      buffer.writeln('  $key: file($filename)');
    }

    return buffer.toString();
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    String dataDescription;
    if (options.data is FormData) {
      dataDescription = _formDataToReadable(options.data as FormData);
    } else {
      dataDescription = _convertToJson(options.data);
    }

    final requestLog =
        'Request: ${options.method} ${options.uri}\nHeaders: ${options.headers}\nData:\n$dataDescription\n';
    await _writeToFile(requestLog);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final dataJson = _convertToJson(response.data);
    final responseLog =
        'Response: ${response.statusCode} ${response.requestOptions.uri}\nData:\n$dataJson\n';
    await _writeToFile(responseLog);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final errorDataJson = _convertToJson(err.response?.data);
    final errorLog =
        'Error: ${err.message}\nURL: ${err.requestOptions.uri}\nResponse Data:\n$errorDataJson\n';
    await _writeToFile(errorLog);
    super.onError(err, handler);
  }
}
