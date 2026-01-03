# PowerShell script to replace Opacity + Transform patterns with AnimatedOpacity + AnimatedScale/AnimatedSlide
# For Impeller rendering engine compatibility

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$totalFixed = 0
$filesWithChanges = @()

Write-Host "Searching for Opacity + Transform patterns in Flutter project..." -ForegroundColor Cyan

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fixCount = 0
    
    # Pattern 1: Transform.scale with Opacity child
    $pattern1 = @'
Transform\.scale\s*\(\s*scale:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),\s*child:
'@
    $replacement1 = @'
AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: $1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $2,
                        child:
'@
    
    # Pattern 2: Transform.translate with Opacity child
    $pattern2 = @'
Transform\.translate\s*\(\s*offset:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),\s*child:
'@
    $replacement2 = @'
AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: $1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $2,
                        child:
'@
    
    # Pattern 3: Opacity with Transform.scale child (reversed order)
    $pattern3 = @'
Opacity\s*\(\s*opacity:\s*([^,]+),\s*child:\s*Transform\.scale\s*\(\s*scale:\s*([^,]+),\s*child:
'@
    $replacement3 = @'
AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $1,
                        child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: $2,
                      child:
'@
    
    # Pattern 4: Opacity with Transform.translate child (reversed order)
    $pattern4 = @'
Opacity\s*\(\s*opacity:\s*([^,]+),\s*child:\s*Transform\.translate\s*\(\s*offset:\s*([^,]+),\s*child:
'@
    $replacement4 = @'
AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $1,
                        child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: $2,
                      child:
'@
    
    # Pattern 5: Transform.scale + Transform.translate + Opacity (nested transforms)
    $pattern5 = @'
Transform\.scale\s*\(\s*scale:\s*([^,]+),\s*child:\s*Transform\.translate\s*\(\s*offset:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),\s*child:
'@
    $replacement5 = @'
AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: $1,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        offset: $2,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: $3,
                          child:
'@
    
    # Pattern 6: For TweenAnimationBuilder patterns with Transform.scale + Opacity
    $pattern6 = @'
return\s+Transform\.scale\s*\(\s*scale:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),
'@
    $replacement6 = @'
return AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: $1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $2,
'@
    
    # Pattern 7: For TweenAnimationBuilder patterns with Transform.translate + Opacity
    $pattern7 = @'
return\s+Transform\.translate\s*\(\s*offset:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),
'@
    $replacement7 = @'
return AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: $1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $2,
'@
    
    # Apply all patterns
    if ($content -match $pattern1) {
        $content = $content -replace $pattern1, $replacement1
        $fixCount++
    }
    if ($content -match $pattern2) {
        $content = $content -replace $pattern2, $replacement2
        $fixCount++
    }
    if ($content -match $pattern3) {
        $content = $content -replace $pattern3, $replacement3
        $fixCount++
    }
    if ($content -match $pattern4) {
        $content = $content -replace $pattern4, $replacement4
        $fixCount++
    }
    if ($content -match $pattern5) {
        $content = $content -replace $pattern5, $replacement5
        $fixCount++
    }
    if ($content -match $pattern6) {
        $content = $content -replace $pattern6, $replacement6
        $fixCount++
    }
    if ($content -match $pattern7) {
        $content = $content -replace $pattern7, $replacement7
        $fixCount++
    }
    
    # Additional specific patterns for common cases
    
    # Pattern for AnimatedBuilder with Transform.scale + Opacity
    $pattern8 = @'
builder:\s*\(context,\s*value,\s*child\)\s*{\s*return\s+Transform\.scale\s*\(\s*scale:\s*([^,]+),\s*child:\s*Opacity\s*\(\s*opacity:\s*([^,]+),
'@
    $replacement8 = @'
builder: (context, value, child) {
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: $1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: $2,
'@
    
    if ($content -match $pattern8) {
        $content = $content -replace $pattern8, $replacement8
        $fixCount++
    }
    
    # Handle AnimatedSlide offset conversion (if offset is not already in the right format)
    # Convert numeric offsets to Offset(x, y) format for AnimatedSlide
    $content = $content -replace 'AnimatedSlide\(\s*duration:\s*const\s+Duration\(milliseconds:\s*300\),\s*offset:\s*Offset\(([^,]+),\s*([^)]+)\)', @'
AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: Offset($1 / MediaQuery.of(context).size.width, $2 / MediaQuery.of(context).size.height)
'@
    
    if ($content -ne $originalContent) {
        # Remove BOM if present
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        
        $totalFixed += $fixCount
        $filesWithChanges += @{
            Path = $file.FullName.Replace($PWD.Path + "\", "")
            Count = $fixCount
        }
        
        Write-Host "Fixed $fixCount Opacity + Transform patterns in: " -NoNewline
        Write-Host "$($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`nTotal Opacity + Transform patterns fixed: " -NoNewline -ForegroundColor Yellow
Write-Host "$totalFixed" -ForegroundColor Green

Write-Host "`nFiles that need manual verification:" -ForegroundColor Cyan
foreach ($change in $filesWithChanges) {
    Write-Host "  - $($change.Path) ($($change.Count) changes)" -ForegroundColor White
}

Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "1. AnimatedSlide requires offsets as fractions of screen size (0.0 to 1.0)" -ForegroundColor White
Write-Host "2. You may need to adjust offset values manually for AnimatedSlide widgets" -ForegroundColor White
Write-Host "3. Review the duration values - 300ms is used as default but you can adjust" -ForegroundColor White
Write-Host "4. Test animations thoroughly to ensure they look correct" -ForegroundColor White

Write-Host "`nFor AnimatedSlide, convert pixel offsets like this:" -ForegroundColor Cyan
Write-Host "  Offset(20, 0) → Offset(0.05, 0)  // assuming ~400px screen width" -ForegroundColor Gray
Write-Host "  Offset(0, 30) → Offset(0, 0.04)  // assuming ~750px screen height" -ForegroundColor Gray