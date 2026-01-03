# PowerShell script to identify and help fix Impeller opacity issues
# Run this from your Flutter project root

Write-Host "Flutter Impeller Opacity Issue Scanner" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Function to search for patterns
function Search-Pattern {
    param(
        [string]$Pattern,
        [string]$Description,
        [string]$Color = "Yellow"
    )
    
    Write-Host "`n$Description" -ForegroundColor $Color
    $results = Select-String -Path "lib/**/*.dart" -Pattern $Pattern -SimpleMatch
    
    if ($results.Count -eq 0) {
        Write-Host "  ✓ No issues found" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Found $($results.Count) potential issues:" -ForegroundColor $Color
        foreach ($result in $results) {
            $relativePath = $result.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
            Write-Host "    - $relativePath`:$($result.LineNumber)" -ForegroundColor DarkGray
        }
    }
    
    return $results
}

# Function to search for regex patterns
function Search-RegexPattern {
    param(
        [string]$Pattern,
        [string]$Description,
        [string]$Color = "Yellow"
    )
    
    Write-Host "`n$Description" -ForegroundColor $Color
    $results = Select-String -Path "lib/**/*.dart" -Pattern $Pattern
    
    if ($results.Count -eq 0) {
        Write-Host "  ✓ No issues found" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Found $($results.Count) potential issues:" -ForegroundColor $Color
        foreach ($result in $results) {
            $relativePath = $result.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
            Write-Host "    - $relativePath`:$($result.LineNumber)" -ForegroundColor DarkGray
        }
    }
    
    return $results
}

Write-Host "`n1. Checking for problematic Opacity patterns..." -ForegroundColor White
Write-Host "================================================" -ForegroundColor White

# Check for Opacity widgets (might cause Impeller issues)
$opacityIssues = Search-Pattern -Pattern "Opacity(" -Description "Opacity widgets (potential Impeller issues)" -Color "Red"

# Check for AnimatedOpacity (should be replaced with FadeTransition)
$animatedOpacityIssues = Search-Pattern -Pattern "AnimatedOpacity(" -Description "AnimatedOpacity widgets (replace with FadeTransition)" -Color "Red"

# Check for BackdropFilter wrapped in Opacity (major Impeller issue)
Write-Host "`n2. Checking for BackdropFilter patterns..." -ForegroundColor White
Write-Host "===========================================" -ForegroundColor White

$backdropFilterFiles = Select-String -Path "lib/**/*.dart" -Pattern "BackdropFilter" -SimpleMatch
if ($backdropFilterFiles.Count -gt 0) {
    Write-Host "  Found $($backdropFilterFiles.Count) files with BackdropFilter" -ForegroundColor Yellow
    Write-Host "  Checking if any are wrapped in Opacity..." -ForegroundColor Gray
    
    $problematicCount = 0
    foreach ($file in $backdropFilterFiles | Select-Object -Unique Path) {
        $content = Get-Content $file.Path -Raw
        # Simple heuristic: check if Opacity appears before BackdropFilter in the same widget tree
        if ($content -match "Opacity[\s\S]{0,500}BackdropFilter") {
            $problematicCount++
            $relativePath = $file.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
            Write-Host "    ⚠ Potential issue in: $relativePath" -ForegroundColor Red
        }
    }
    
    if ($problematicCount -eq 0) {
        Write-Host "  ✓ No BackdropFilter wrapped in Opacity found" -ForegroundColor Green
    }
} else {
    Write-Host "  ✓ No BackdropFilter widgets found" -ForegroundColor Green
}

# Check for ShaderMask patterns
$shaderMaskIssues = Search-Pattern -Pattern "ShaderMask(" -Description "ShaderMask widgets (check for Opacity wrapping)" -Color "Yellow"

# Check for ColorFiltered patterns
$colorFilteredIssues = Search-Pattern -Pattern "ColorFiltered(" -Description "ColorFiltered widgets (check for Opacity wrapping)" -Color "Yellow"

Write-Host "`n3. Checking for performance patterns..." -ForegroundColor White
Write-Host "========================================" -ForegroundColor White

# Check for large blur radii
$largeBlurFiles = Select-String -Path "lib/**/*.dart" -Pattern "sigma[XY]:\s*([2-9]\d+|\d{3,})" 
if ($largeBlurFiles.Count -gt 0) {
    Write-Host "  ⚠ Found $($largeBlurFiles.Count) large blur radii (>20)" -ForegroundColor Yellow
    foreach ($result in $largeBlurFiles | Select-Object -First 5) {
        $relativePath = $result.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
        Write-Host "    - $relativePath`:$($result.LineNumber): $($result.Line.Trim())" -ForegroundColor DarkGray
    }
    if ($largeBlurFiles.Count -gt 5) {
        Write-Host "    ... and $($largeBlurFiles.Count - 5) more" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ✓ No large blur radii found" -ForegroundColor Green
}

# Check for RepaintBoundary usage
$repaintBoundaryCount = (Select-String -Path "lib/**/*.dart" -Pattern "RepaintBoundary" -SimpleMatch).Count
Write-Host "  ℹ RepaintBoundary widgets found: $repaintBoundaryCount" -ForegroundColor Cyan
if ($repaintBoundaryCount -lt 5) {
    Write-Host "    Consider adding RepaintBoundary around heavy static content" -ForegroundColor DarkYellow
}

Write-Host "`n4. Checking for withValues(alpha:) usage..." -ForegroundColor White
Write-Host "============================================" -ForegroundColor White

$withValuesCount = (Select-String -Path "lib/**/*.dart" -Pattern "withValues\s*\(\s*alpha:" -SimpleMatch).Count
Write-Host "  ℹ withValues(alpha:) usage: $withValuesCount instances" -ForegroundColor Cyan
Write-Host "    This is the correct modern approach (replaces withOpacity)" -ForegroundColor Green

# Check for deprecated withOpacity
$withOpacityIssues = Search-Pattern -Pattern "withOpacity(" -Description "Deprecated withOpacity() calls (use withValues(alpha:))" -Color "Yellow"

Write-Host "`n5. Summary and Recommendations" -ForegroundColor White
Write-Host "==============================" -ForegroundColor White

$totalIssues = $opacityIssues.Count + $animatedOpacityIssues.Count + $withOpacityIssues.Count

if ($totalIssues -eq 0) {
    Write-Host "`n✅ Great! No major opacity issues found." -ForegroundColor Green
    Write-Host "   Your app should work well with Impeller." -ForegroundColor Green
} else {
    Write-Host "`n⚠ Found $totalIssues potential issues that may cause Impeller errors." -ForegroundColor Yellow
    
    Write-Host "`nRecommended fixes:" -ForegroundColor Cyan
    if ($opacityIssues.Count -gt 0) {
        Write-Host "  1. Replace Opacity widgets with FadeTransition or color alpha" -ForegroundColor White
    }
    if ($animatedOpacityIssues.Count -gt 0) {
        Write-Host "  2. Replace AnimatedOpacity with FadeTransition" -ForegroundColor White
    }
    if ($withOpacityIssues.Count -gt 0) {
        Write-Host "  3. Replace withOpacity() with withValues(alpha:)" -ForegroundColor White
    }
    
    Write-Host "`nUse the SafeFade widget from lib/core/widgets/safe_fade.dart" -ForegroundColor Cyan
    Write-Host "for a standardized approach to fade transitions." -ForegroundColor Cyan
}

Write-Host "`n6. Testing with Impeller" -ForegroundColor White
Write-Host "========================" -ForegroundColor White
Write-Host "Run your app with Impeller enabled to test:" -ForegroundColor Cyan
Write-Host "  flutter run --enable-impeller" -ForegroundColor Yellow

Write-Host "`nFor detailed fixes, see OPACITY_TRANSFORM_FIXES.md" -ForegroundColor Cyan

# Option to generate a fix report
Write-Host "`nGenerate detailed fix report? (y/n): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq 'y' -or $response -eq 'Y') {
    $reportPath = "impeller-opacity-report.txt"
    
    @"
Flutter Impeller Opacity Issue Report
Generated: $(Get-Date)
=====================================

ISSUES FOUND:
- Opacity widgets: $($opacityIssues.Count)
- AnimatedOpacity widgets: $($animatedOpacityIssues.Count)
- Deprecated withOpacity calls: $($withOpacityIssues.Count)
- Large blur radii: $($largeBlurFiles.Count)

OPACITY WIDGETS:
"@ | Out-File $reportPath
    
    foreach ($issue in $opacityIssues) {
        $relativePath = $issue.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
        "$relativePath`:$($issue.LineNumber): $($issue.Line.Trim())" | Out-File $reportPath -Append
    }
    
    @"

ANIMATEDOPACITY WIDGETS:
"@ | Out-File $reportPath -Append
    
    foreach ($issue in $animatedOpacityIssues) {
        $relativePath = $issue.Path.Replace($PWD.Path + "\", "").Replace("\", "/")
        "$relativePath`:$($issue.LineNumber): $($issue.Line.Trim())" | Out-File $reportPath -Append
    }
    
    Write-Host "`nReport saved to: $reportPath" -ForegroundColor Green
}

Write-Host "`nDone! Happy coding with Impeller! 🚀" -ForegroundColor Cyan