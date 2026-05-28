import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('Error: Could not find lib folder. Run this script from the mobile_app directory.');
    return;
  }

  int fixedCount = 0;
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final file = entity;
      String content = file.readAsStringSync();
      bool changed = false;

      if (content.contains('FontWeight.black')) {
        content = content.replaceAll('FontWeight.black', 'FontWeight.w900');
        changed = true;
      }
      if (content.contains('MainAxisAlignment.between')) {
        content = content.replaceAll('MainAxisAlignment.between', 'MainAxisAlignment.spaceBetween');
        changed = true;
      }

      if (changed) {
        file.writeAsStringSync(content);
        print('Fixed: ${file.path}');
        fixedCount++;
      }
    }
  });

  print('Done! Successfully fixed $fixedCount files.');
}
