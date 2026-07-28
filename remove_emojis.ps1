$files = @(
    "c:\Users\nayya\Portfolio_Project\backend\src\routes\medications.js",
    "c:\Users\nayya\Portfolio_Project\frontend\lib\views\dashboard\home_screen.dart",
    "c:\Users\nayya\Portfolio_Project\frontend\lib\views\dashboard\dependent_dashboard_screen.dart"
)

foreach ($file in $files) {
    Write-Host "Processing: $file"
    $content = [System.IO.File]::ReadAllText($file)
    
    # Remove common emoji patterns
    $content = $content -replace '[🔍📦❌✅]', ''
    
    # Remove remaining merge conflict markers if any
    $content = $content -replace '(?m)^<<<<<<< .*$', ''
    $content = $content -replace '(?m)^=======$', ''
    $content = $content -replace '(?m)^>>>>>>> .*$', ''
    
    [System.IO.File]::WriteAllText($file, $content)
    Write-Host "Done: $file"
}
Write-Host "All files processed"

