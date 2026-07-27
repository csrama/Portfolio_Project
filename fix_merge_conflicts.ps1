# PowerShell script to fix merge conflict markers in home_screen.dart
# Keeps the Stashed changes version (after =======)

$filePath = "c:\Users\janab\Portfolio_Project\frontend\lib\views\dashboard\home_screen.dart"
$content = Get-Content $filePath -Raw

# Replace merge conflict blocks, keeping the stashed version
# Pattern: <<<<<<< ... \n(upstream)\n=======\n(stashed)\n>>>>>>> ... \n
$regex = '(?s)<<<<<<< .*?\n(.*?)=======\n(.*?)>>>>>>> .*?\n'
$fixed = [regex]::Replace($content, $regex, {
    param($match)
    # Return the stashed changes (group 2)
    return $match.Groups[2].Value
})

# Count markers before/after
$before = [regex]::Matches($content, '<<<<<<<').Count
$after = [regex]::Matches($fixed, '<<<<<<<').Count

Write-Host "Conflict markers before: $before"
Write-Host "Conflict markers after: $after"

# Write the fixed content
[System.IO.File]::WriteAllText($filePath, $fixed, [System.Text.UTF8Encoding]::new($false))
Write-Host "File saved successfully!"

