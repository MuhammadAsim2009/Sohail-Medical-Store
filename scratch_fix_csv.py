import re

file_path = r"d:\pharmacy\lib\screens\ledger_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add imports
if "dart:io" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'dart:io';\nimport 'package:flutter/material.dart';\nimport 'package:file_picker/file_picker.dart';")

# Replace _exportCSV
old_method = '''  void _exportCSV() {
    AppFeedback.show(context, 'Exporting CSV...', type: AppFeedbackType.success);
  }'''

new_method = '''  Future<void> _exportCSV() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export CSV',
      fileName: 'ledger_export.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path == null) return;

    try {
      final file = File(path);
      final sink = file.openWrite();

      switch (_tabController.index) {
        case 0:
          sink.writeln('Date,Reference,Description,Category,Type,Amount,Balance');
          for (var e in _generalLedger) {
            final amt = e.debit > 0 ? e.debit : (e.credit > 0 ? -e.credit : 0);
            sink.writeln('\,"\","\","\","\",\,\');
          }
          break;
        case 1:
          sink.writeln('Date,Reference,Description,Debit,Credit,Balance');
          for (var e in _customerStatements) {
            sink.writeln('\,"\","\",\,\,\');
          }
          break;
        case 2:
          sink.writeln('Date,Reference,Description,Debit,Credit,Balance');
          for (var e in _supplierStatements) {
            sink.writeln('\,"\","\",\,\,\');
          }
          break;
      }

      await sink.flush();
      await sink.close();
      if (mounted) {
        AppFeedback.show(context, 'Exported successfully to \', type: AppFeedbackType.success);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(context, 'Export failed: \', type: AppFeedbackType.error);
      }
    }
  }'''

if old_method in content:
    content = content.replace(old_method, new_method)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Success")
else:
    print("Target old_method not found")
