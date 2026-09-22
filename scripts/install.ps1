<#
.SYNOPSIS
Lontar AIEL: Universal Windows Installation Script
Document Version: v0.1.0-alpha.2026-09-22-19:00
#>

Write-Host "📦 Welcome to Lontar AIEL Zero-Friction Setup!" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray

# 1. Dependency Checks
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Git is required but it's not installed. Please install Git for Windows."
    exit 1
}

if (-not (Get-Command "elixir" -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Elixir is required but it's not installed."
    Write-Host "👉 Install it via Winget: winget install Elixir.Elixir" -ForegroundColor Yellow
    exit 1
}

# 2. Setup Directories
$InstallDir = "$env:USERPROFILE\lontar-aiel"
$BinDir = "$env:USERPROFILE\.local\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
}

# 3. Clone or Update Repository
if (Test-Path "$InstallDir\.git") {
    Write-Host "🔄 Updating existing Lontar AIEL installation..." -ForegroundColor Blue
    Set-Location $InstallDir
    git fetch
    git checkout confluent-alpha 2>$null
    if (-not $?) { git checkout main }
    git pull origin confluent-alpha 2>$null
    if (-not $?) { git pull origin main }
} else {
    Write-Host "📥 Downloading Lontar AIEL..." -ForegroundColor Blue
    $gitArgs = "clone", "--branch", "confluent-alpha", "https://github.com/zelasar-rmd/lontar-aiel.git", $InstallDir
    $process = Start-Process git -ArgumentList $gitArgs -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        git clone https://github.com/zelasar-rmd/lontar-aiel.git $InstallDir
    }
}

# 4. Create Executable Wrapper
Write-Host "⚙️ Creating 'lontar' CLI wrapper..." -ForegroundColor Blue
$BatWrapper = "$BinDir\lontar.bat"
$BatContent = "@echo off`r`nelixir `"$InstallDir\scripts\calculate_emission.exs`" %*"
Set-Content -Path $BatWrapper -Value $BatContent -Encoding UTF8

# 5. Path Setup Instructions
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($BinDir)) {
    Write-Host "⚠️  NOTE: '$BinDir' is not in your PATH." -ForegroundColor Yellow
    Write-Host "👉 Adding it to your User PATH environment variable automatically..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$UserPath", "User")
    $env:PATH = "$BinDir;$env:PATH"
    Write-Host "✅ PATH updated. You may need to restart your terminal to use 'lontar' globally." -ForegroundColor Green
}

Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host "🚀 Initializing Lontar AIEL and reviewing Privacy Protocol..." -ForegroundColor Magenta
Write-Host ""

# 6. Trigger initial opt-in
& $BatWrapper opt-in
