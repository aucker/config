# PowerShell stow-like script for Windows dotfiles
# This script handles Windows-specific configuration files

Write-Host "Installing Windows dotfiles..." -ForegroundColor Green

# Native Windows selections are kept alongside the POSIX profiles. The
# profile contains logical groups; this table owns their Windows path mapping.
$profilePath = Join-Path $PSScriptRoot 'profiles\windows'
$configGroups = [ordered]@{
    'powershell' = [ordered]@{
        'Microsoft.PowerShell_profile.ps1' = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    }
    'starship' = [ordered]@{
        'starship.toml' = "$env:USERPROFILE\.config\starship.toml"
    }
    'vscode' = [ordered]@{
        'vscode/settings.json' = "$env:APPDATA\Code\User\settings.json"
        'vscode/keybindings.json' = "$env:APPDATA\Code\User\keybindings.json"
    }
}

if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "Windows profile not found: $profilePath"
}

$selectedGroups = Get-Content -LiteralPath $profilePath | ForEach-Object {
    ($_ -split '#', 2)[0].Trim()
} | Where-Object { $_ }

# Function to create symbolic links (similar to stow)
function Install-Config {
    param(
        [string]$SourceFile,
        [string]$TargetPath
    )
    
    $sourcePath = Join-Path $PSScriptRoot "windows\$SourceFile"
    
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        Write-Host "⚠️  Source file not found: $sourcePath" -ForegroundColor Yellow
        return
    }
    
    # Create target directory if it doesn't exist
    $targetDir = Split-Path $TargetPath -Parent
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        Write-Host "Creating directory: $targetDir" -ForegroundColor Cyan
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }
    
    # Check if target already exists
    if (Test-Path -LiteralPath $TargetPath) {
        Write-Host "⚠️  Target already exists: $TargetPath" -ForegroundColor Yellow
        Write-Host "   You may need to backup and remove the existing file first" -ForegroundColor Yellow
        return
    }
    
    try {
        # Create symbolic link
        New-Item -Path $TargetPath -ItemType SymbolicLink -Value $sourcePath -Force | Out-Null
        Write-Host "✅ Linked: $SourceFile -> $TargetPath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to link $SourceFile : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Try running as Administrator for symbolic link creation" -ForegroundColor Yellow
    }
}

# Install each configuration file
Write-Host "📁 Processing Windows configurations..." -ForegroundColor Blue

foreach ($group in $selectedGroups) {
    if (-not $configGroups.Contains($group)) {
        throw "Unknown Windows configuration group '$group' in $profilePath"
    }

    Write-Host "[$group]" -ForegroundColor Blue
    foreach ($config in $configGroups[$group].GetEnumerator()) {
        Install-Config -SourceFile $config.Key -TargetPath $config.Value
        Write-Host "" # Empty line for readability
    }
}

Write-Host "Windows dotfiles installation complete!" -ForegroundColor Green
Write-Host "Note: If symbolic links failed, try running as Administrator" -ForegroundColor Yellow
