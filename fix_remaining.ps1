# Fix remaining merge artifacts in home_screen.dart
$path = "frontend/lib/views/dashboard/home_screen.dart"
$content = Get-Content -Path $path -Raw

# 1. Remove all "Stashed changes" text artifacts
$fixed = $content -replace 'Stashed changes', ''

# 2. Fix _weekdayNameFromDate - remove duplicated entries
$fixed = $fixed -replace '(?ms)const names = \[.*?الاثنين.*?السبت.*?الأحد.*?\];', 'const names = [
      '\''الاثنين'\'',
      '\''الثلاثاء'\'',
      '\''الأربعاء'\'',
      '\''الخميس'\'',
      '\''الجمعة'\'',
      '\''السبت'\'',
      '\''الأحد'\'',
    ];'

# 3. Fix duplicate _checkInteractionsFor method
$fixed = $fixed -replace '(?ms)Future<List<DrugInteraction>> _checkInteractionsFor\(\s*String newMedName\s*\) async \{.*?Future<List<DrugInteraction>> _checkInteractionsFor\(String newMedName\) async \{', 'Future<List<DrugInteraction>> _checkInteractionsFor(String newMedName) async {'
$fixed = $fixed -replace '(?ms)/\/\/\/ يفحص دواء معيّن.*?\n.*?\/\/\/ يُستخدم لعرض تحذير فوري.*?\n', ''

# 4. Fix duplicate _buildInteractionDetailTile
$fixed = $fixed -replace '(?ms)Widget _buildInteractionDetailTile\(DrugInteraction i,\s*\{bool emphasize = false\}\) \{.*?Widget _buildInteractionDetailTile\(\s*DrugInteraction i,\s*\{', 'Widget _buildInteractionDetailTile(DrugInteraction i, {'
$fixed = $fixed -replace '(?ms)/\/\/\/ يبني نص \+ لون التفاصيل.*?\n.*?\n', ''

# 5. Fix duplicate style in ElevatedButton
$fixed = $fixed -replace '(?ms)style: ElevatedButton\.styleFrom\(\s*backgroundColor: Colors\.red,\s*\),\s*style: ElevatedButton\.styleFrom\(backgroundColor: Colors\.red\),', 'style: ElevatedButton.styleFrom(backgroundColor: Colors.red),'

# 6. Fix duplicate debugPrint
$fixed = $fixed -replace "(?ms)debugPrint\(' Error with \$\{test\['path'\]\}: \$e'\);\s*debugPrint\('❌ Error with \$\{test\['path'\]\}: \$e'\);", "debugPrint('❌ Error with \${test['path']}: \$e');"

# 7. Fix duplicate SnackBar content
$fixed = $fixed -replace "(?ms)content: Text\(' تم حذف الدواء بنجاح'\),\s*content: Text\('✅ تم حذف الدواء بنجاح'\),", "content: Text('✅ تم حذف الدواء بنجاح'),"
$fixed = $fixed -replace "(?ms)content: Text\(' فشل الحذف: الكود \$lastStatusCode'\),\s*content: Text\('❌ فشل الحذف: الكود \$lastStatusCode'\),", "content: Text('❌ فشل الحذف: الكود \$lastStatusCode'),"

# 8. Fix duplicate content/backgroundColor in _showEditDependentDialog SnackBar
$fixed = $fixed -replace "(?ms)content: Text\(success \? 'تم التحديث بنجاح ' : 'فشل التحديث'\),\s*backgroundColor: success \? const Color\(0xFF1D9E75\) : Colors\.red,\s*content: Text\(\s*success \? 'تم التحديث بنجاح ✅' : 'فشل التحديث',\s*\),\s*backgroundColor: success\s*\?\s*const Color\(0xFF1D9E75\)\s*:\s*Colors\.red,", "content: Text(success ? 'تم التحديث بنجاح ✅' : 'فشل التحديث'),
                      backgroundColor: success ? const Color(0xFF1D9E75) : Colors.red,"

# 9. Fix duplicate test entries
$fixed = $fixed -replace "(?ms)\{'method': 'POST', 'path': '/medications/\$\{med\.id\}', 'body': '\{\"_method\":\"DELETE\"\}'},\s*\{'method': 'POST', 'path': '/medication/\$\{med\.id\}', 'body': '\{\"_method\":\"DELETE\"\}'},\s*\{", "{'method': 'POST', 'path': '/medications/\${med.id}', 'body': '{\"_method\":\"DELETE\"}'},
      {'method': 'POST', 'path': '/medication/\${med.id}', 'body': '{\"_method\":\"DELETE\"}'},
      {"

# 10. Fix _selectSuggestion duplicate code
$fixed = $fixed -replace "(?ms)_nameController\.text = _medicineDisplayName\(suggestion, langCode\);\s*_dosageController\.text = suggestion\['dosage'\] \?\? '';\s*final nameEn = \(suggestion\['name_en'\] \?\? ''\)\.toString\(\);\s*final nameAr = \(suggestion\['name_ar'\] \?\? ''\)\.toString\(\);\s*_nameController\.text = nameAr\.isNotEmpty \? '\$nameEn — \$nameAr' : nameEn;\s*_dosageController\.text = suggestion\['dosage'\] \?\? '';", "_nameController.text = _medicineDisplayName(suggestion, langCode);
      _dosageController.text = suggestion['dosage'] ?? '';"

Set-Content -Path $path -Value $fixed -NoNewline
Write-Host "Fixed remaining artifacts in home_screen.dart"

# Verify no more Stashed changes artifacts
$remaining = Select-String -Path $path -Pattern 'Stashed changes'
if ($remaining) {
    Write-Host "WARNING: Still found Stashed changes at lines:"
    $remaining | ForEach-Object { Write-Host $_.LineNumber }
} else {
    Write-Host "No more Stashed changes artifacts found!"
}

