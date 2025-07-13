# PowerShell stow-like script for Windows dotfiles
# This script handles Windows-specific configuration files

Write-Host "Installing Windows dotfiles..." -ForegroundColor Green

# Define target locations for different config types
$configPaths = @{
    'Microsoft.PowerShell_profile.ps1' = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    'starship.toml' = "$env:USERPROFILE\.config\starship.toml"
    'vscode/settings.json' = "$env:APPDATA\Code\User\settings.json"
    'vscode/keybindings.json' = "$env:APPDATA\Code\User\keybindings.json"
}

# Function to create symbolic links (similar to stow)
function Install-Config {
    param(
        [string]$SourceFile,
        [string]$TargetPath
    )
    
    $sourcePath = Join-Path $PSScriptRoot "windows\$SourceFile"
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "⚠️  Source file not found: $sourcePath" -ForegroundColor Yellow
        return
    }
    
    # Create target directory if it doesn't exist
    $targetDir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $targetDir)) {
        Write-Host "Creating directory: $targetDir" -ForegroundColor Cyan
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }
    
    # Check if target already exists
    if (Test-Path $TargetPath) {
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

foreach ($config in $configPaths.GetEnumerator()) {
    Install-Config -SourceFile $config.Key -TargetPath $config.Value
    Write-Host "" # Empty line for readability
}

Write-Host "Windows dotfiles installation complete!" -ForegroundColor Green
Write-Host "Note: If symbolic links failed, try running as Administrator" -ForegroundColor Yellow
