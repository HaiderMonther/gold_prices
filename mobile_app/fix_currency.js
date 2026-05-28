const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

const regex = /String _formatCurrency\(num value\) \{[\s\S]*?trim\(\);\s*\}/g;
const replacement = `String _formatCurrency(dynamic value) {
    num parsedValue = 0;
    if (value != null) {
      if (value is num) {
        parsedValue = value;
      } else if (value is String) {
        parsedValue = double.tryParse(value) ?? 0;
      }
    }
    return intl.NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(parsedValue).trim();
  }`;

walkDir('lib/screens', (filePath) => {
  if (filePath.endsWith('.dart')) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.includes('String _formatCurrency(num value)')) {
      let newContent = content.replace(regex, replacement);
      if (newContent !== content) {
        fs.writeFileSync(filePath, newContent);
        console.log('Successfully replaced in ' + filePath);
      } else {
        console.log('Found but failed to replace in ' + filePath);
      }
    }
  }
});
