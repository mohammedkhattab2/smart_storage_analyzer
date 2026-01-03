# PowerShell script to reverse opacity changes - replace withOpacity back to withValues(alpha:)
# Save this file and run: .\reverse-opacity-changes.ps1

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$totalFixed = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Replace withOpacity back to withValues(alpha:)
    $content = $content -replace '\.withOpacity\s*\(([^)]+)\)', '.withValues(alpha: $1)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $matches = ([regex]::Matches($originalContent, '\.withOpacity\s*\(')).Count
        $totalFixed += $matches
        Write-Host "Reversed $matches occurrences in: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`nTotal reversals applied: $totalFixed" -ForegroundColor Cyan
Write-Host "`nWarning: This will restore the Impeller rendering errors!" -ForegroundColor Red