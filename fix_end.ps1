$filePath = 'c:/Users/janab/Portfolio_Project/frontend/lib/views/dashboard/dependent_dashboard_screen.dart'
$content = Get-Content $filePath -Raw
if ($content.EndsWith('_AddDependentMedication') -or $content.EndsWith('_AddDependentMedication' + [Environment]::NewLine)) {
    $trim = '_AddDependentMedication'
    $len = $trim.Length
    if ($content.EndsWith([Environment]::NewLine)) { $len = $len + [Environment]::NewLine.Length }
    $newContent = $content.Substring(0, $content.Length - $len)
    $newContent = $newContent + '_AddDependentMedicationSheetState();' + [Environment]::NewLine + '}' + [Environment]::NewLine
    Set-Content $filePath $newContent -NoNewline
    Write-Host 'Fixed!'
} else {
    Write-Host 'Ending:'
    Write-Host $content.Substring([Math]::Max(0, $content.Length - 60))
}

