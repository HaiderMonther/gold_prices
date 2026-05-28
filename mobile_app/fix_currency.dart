import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  if (!dir.existsSync()) {
    print('dir not found');
    return;
  }
  
  final regex = RegExp(r'String _formatCurrency\(num value\) \{[\s\S]*?\.format\(value\)\.trim\(\);\s*\}');
  
  final replacement = '''String _formatCurrency(dynamic value) {
    num parsedValue = 0;
    if (value is num) {
      parsedValue = value;
    } else if (value is String) {
      parsedValue = double.tryParse(value) ?? 0;
    }
    return intl.NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(parsedValue).trim();
  }''';

  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      if (content.contains('String _formatCurrency(num value)')) {
        content = content.replaceAll(regex, replacement);
        file.writeAsStringSync(content);
        print('Updated \${file.path}');
      }
    }
  }
}
