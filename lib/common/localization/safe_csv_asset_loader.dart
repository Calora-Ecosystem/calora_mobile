import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/services.dart';

/// A deterministic CSV loader for the app's translations.
///
/// The stock [CsvAssetLoader] auto-detects the text (quote) delimiter as
/// whichever of `"`, `'` or `”` appears **first** in the file. Because the
/// Uzbek column contains apostrophe-like characters, that heuristic is fragile:
/// if a future edit ever places an apostrophe row above the first
/// double-quoted field, the parser would pick `'` as the quote character and
/// silently mis-parse the whole file — making **every** key render as its raw
/// key (e.g. `ft_food_title`, `ob_skip`) instead of its translation.
///
/// This loader removes that ambiguity entirely. It fixes the delimiters to the
/// standard RFC-4180 `,` field / `"` text delimiters and a `\n` end-of-line,
/// and normalizes any Windows/CR line endings first, so parsing never depends
/// on row ordering or the editor that last touched the file.
class SafeCsvAssetLoader extends AssetLoader {
  SafeCsvAssetLoader({
    this.extraPath = 'assets/localization/translations_extra.csv',
  });

  final String? extraPath;

  CSVParser? _parser;
  CSVParser? _extraParser;
  bool _extraLoaded = false;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    _parser ??= parserFor(await rootBundle.loadString(path));
    if (!_extraLoaded) {
      _extraLoaded = true;
      final extra = extraPath;
      if (extra != null) {
        try {
          _extraParser = parserFor(await rootBundle.loadString(extra));
        } catch (_) {
          _extraParser = null;
        }
      }
    }
    final key = locale.toString();
    return {
      ...?_extraParser?.getLanguageMap(key),
      ..._parser!.getLanguageMap(key),
    };
  }

  static CSVParser parserFor(String raw) => CSVParser(
    raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    fieldDelimiter: ',',
    eol: '\n',
    useAutodetect: false,
  );
}
