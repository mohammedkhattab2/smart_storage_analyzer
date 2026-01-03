# PowerShell script to fix Opacity widgets for Impeller compatibility
# This replaces problematic Opacity widgets with FadeTransition

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$totalFixed = 0
$manualFixes = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileChanged = $false
    
    # Pattern 1: Opacity with animation.value in builders
    if ($content -match 'builder:\s*\([^)]+\)\s*\{\s*return\s+Opacity\s*\(\s*opacity:\s*value') {
        $content = $content -replace '(builder:\s*\([^)]+\)\s*\{\s*return\s+)Opacity\s*\(\s*opacity:\s*value([^,]*),', '$1FadeTransition(opacity: AlwaysStoppedAnimation(value$2),'
        $fileChanged = $true
    }
    
    # Pattern 2: Opacity with _fadeAnimation.value
    if ($content -match 'Opacity\s*\(\s*opacity:\s*_\w+Animation\.value') {
        $manualFixes += @{
            File = $file.Name
            Pattern = "Opacity(opacity: _someAnimation.value"
            Fix = "FadeTransition(opacity: _someAnimation"
        }
    }
    
    # Pattern 3: Simple Opacity with value parameter
    $content = $content -replace 'return\s+Opacity\s*\(\s*opacity:\s*value\s*,', 'return FadeTransition(opacity: AlwaysStoppedAnimation(value),'
    
    # Pattern 4: Opacity with clamped values
    $content = $content -replace 'Opacity\s*\(\s*opacity:\s*value\.clamp\(([^)]+)\)\s*,', 'FadeTransition(opacity: AlwaysStoppedAnimation(value.clamp($1)),'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $matches = ([regex]::Matches($originalContent, 'Opacity\s*\(')).Count - ([regex]::Matches($content, 'Opacity\s*\(')).Count
        $totalFixed += $matches
        Write-Host "Fixed $matches Opacity widgets in: $($file.Name)" -ForegroundColor Green
        $fileChanged = $true
    }
}

Write-Host "`nTotal Opacity widgets fixed automatically: $totalFixed" -ForegroundColor Cyan

if ($manualFixes.Count -gt 0) {
    Write-Host "`nThe following files need manual fixes:" -ForegroundColor Yellow
    foreach ($fix in $manualFixes) {
        Write-Host "  File: $($fix.File)" -ForegroundColor Yellow
        Write-Host "  Pattern: $($fix.Pattern)" -ForegroundColor Red
        Write-Host "  Fix: $($fix.Fix)" -ForegroundColor Green
    }
}

Write-Host "`nNote: AnimatedOpacity widgets with static conditions (isVisible ? 1.0 : 0.0) are safe and not changed." -ForegroundColor Blue