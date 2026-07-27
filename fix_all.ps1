function Fix-MergeConflicts {
    param([string]$filePath)
    
    $content = [System.IO.File]::ReadAllText($filePath)
    $original = $content
    
    # Pattern 1: <<<<<<< ... \n(upstream)\n=======\n(stashed)\n>>>>>>> ... \n
    # Keep the stashed version (after =======)
    $regex = '(?s)<<<<<<< .*?\n(.*?)=======\n(.*?)>>>>>>> .*?\n'
    
    $fixed = [regex]::Replace($content, $regex, {
        param($match)
        # Return the stashed changes (group 2)
        return $match.Groups[2].Value
    })
    
    $before = [regex]::Matches($content, '<<<<<<<').Count
    $after = [regex]::Matches($fixed, '<<<<<<<').Count
    
    Write-Host "Before: $before, After: $after"
    
    if ($before -gt 0) {
        [System.IO.File]::WriteAllText($filePath, $fixed, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Fixed!"
    } else {
        Write-Host "No conflicts found."
    }
}

$homeScreen = "c:\Users\janab\Portfolio_Project\frontend\lib\views\dashboard\home_screen.dart"
Fix-MergeConflicts -filePath $homeScreen

