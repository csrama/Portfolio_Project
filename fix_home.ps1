$file = "frontend/lib/views/dashboard/home_screen.dart"
$content = [System.IO.File]::ReadAllText((Resolve-Path $file))

# Fix 1: _weekdayNameFromDate has duplicate days - shorten to 7 unique entries
$content = $content -replace '(?s)const names = \[.*?''];(.*?)^\s+];', @'
  const names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
'@

# Fix 2: _checkInteractionsFor - remove duplicate declaration and Stashed changes leftover
$content = $content -replace '(?s)Future<List<DrugInteraction>> _checkInteractionsFor\(\s*String newMedName\s*\) async \{.*?///.*?///.*?Future<List<DrugInteraction>> _checkInteractionsFor\(String newMedName\) async \{Stashed changes', 'Future<List<DrugInteraction>> _checkInteractionsFor(String newMedName) async {'

# Fix 3: _buildInteractionDetailTile - remove duplicate declaration
$content = $content -replace '(?s)Widget _buildInteractionDetailTile\(DrugInteraction i,\s*\{bool emphasize = false\}\) \{(.*?)///.*?///.*?Widget _buildInteractionDetailTile\(\s*DrugInteraction i, \{\s*bool emphasize = false,\s*\}\) \{Stashed changes', 'Widget _buildInteractionDetailTile(DrugInteraction i, {bool emphasize = false}) {$1'

# Fix 4: _deleteMedication - remove duplicate style: lines  
$content = $content -replace 'style: ElevatedButton\.styleFrom\(\s*backgroundColor: Colors\.red,\s*\),?\s*style: ElevatedButton\.styleFrom\(backgroundColor: Colors\.red\),Stashed changes', 'style: ElevatedButton.styleFrom(backgroundColor: Colors.red),'

# Fix 5: Remove Stashed changes leftover text scattered in tests list
$content = $content -replace ",?\s*\{[\s\S]*?'method': 'POST',[\s\S]*?'body': '\{\\"_method\\":\\"DELETE\\"\}'\},?\s*\{[\s\S]*?'method': 'POST',[\s\S]*?'body': '\{\\"_method\\":\\"DELETE\\"\}'\},Stashed changes", ''

# Fix 6: Remove duplicate debugPrint lines with Stashed changes
$content = $content -replace "debugPrint\(' Error with \$\{test\['path'\]\}: \$e'\);?\s*debugPrint\('❌ Error with \$\{test\['path'\]\}: \$e'\);Stashed changes", "debugPrint(' Error with ${test['path']}: \$e');"

# Fix 7: Remove duplicate SnackBar content lines
$content = $content -replace "content: Text\(' تم حذف الدواء بنجاح'\),\s*content: Text\('✅ تم حذف الدواء بنجاح'\),Stashed changes", "content: Text(' تم حذف الدواء بنجاح'),"
$content = $content -replace "content: Text\(' فشل الحذف: الكود \$lastStatusCode'\),\s*content: Text\('❌ فشل الحذف: الكود \$lastStatusCode'\),Stashed changes", "content: Text(' فشل الحذف: الكود \$lastStatusCode'),"

# Fix 8: _showEditDependentDialog - remove duplicate SnackBar content and backgroundColors
$content = $content -replace "content: Text\(success \? 'تم التحديث بنجاح ' : 'فشل التحديث'\),\s*backgroundColor: success \? const Color\(0xFF1D9E75\) : Colors\.red,\s*content: Text\(\s*success \? 'تم التحديث بنجاح ✅' : 'فشل التحديث',\s*\),\s*backgroundColor: success\s*\?\s*const Color\(0xFF1D9E75\)\s*:\s*Colors\.red,Stashed changes", "content: Text(success ? 'تم التحديث بنجاح ' : 'فشل التحديث'),\n                      backgroundColor: success ? const Color(0xFF1D9E75) : Colors.red,"

# Fix 9: _selectSuggestion - remove duplicated code block
$content = $content -replace "(?s)_nameController\.text = _medicineDisplayName\(suggestion, langCode\);\s*_dosageController\.text = suggestion\['dosage'\] \?\? '';\s*(\s+)final nameEn[\s\S]*?_nameController\.text = nameAr\.isNotEmpty \? '\$nameEn — \$nameAr' : nameEn;[\s\S]*?_dosageController\.text = suggestion\['dosage'\] \?\? '';\s+Stashed changes", "_nameController.text = _medicineDisplayName(suggestion, langCode);\n      _dosageController.text = suggestion['dosage'] ?? '';"

[System.IO.File]::WriteAllText((Resolve-Path $file), $content)
Write-Host "Fixed home_screen.dart"
