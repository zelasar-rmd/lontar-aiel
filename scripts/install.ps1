# Lontar AIEL Universal Installer (Windows PowerShell)

Write-Host "📦 Installing Lontar AIEL CLI..." -ForegroundColor Cyan

# Check Elixir
if (-not (Get-Command "elixir" -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Elixir is not installed." -ForegroundColor Yellow
    Write-Host "Please install Elixir (e.g., 'choco install elixir' or 'winget install Elixir.Elixir') and run this script again."
    exit 1
}

if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Git is not installed." -ForegroundColor Yellow
    Write-Host "Please install Git and run this script again."
    exit 1
}

$DEST_DIR = "$env:USERPROFILE\lontar-aiel"
# Using an existing path folder that usually works or standard script path
$BIN_DIR = "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps"

if (Test-Path "$DEST_DIR\.git") {
    Write-Host "🔄 Updating existing installation at $DEST_DIR..."
    git -C "$DEST_DIR" fetch --all
    git -C "$DEST_DIR" checkout confluent-alpha
    git -C "$DEST_DIR" pull origin confluent-alpha
} else {
    Write-Host "📥 Cloning Lontar AIEL repository to $DEST_DIR..."
    git clone -b confluent-alpha https://github.com/zelasar-rmd/lontar-aiel.git "$DEST_DIR"
}

Write-Host "⚙️  Setting up CLI wrapper 'lontar.bat'..."
if (-not (Test-Path $BIN_DIR)) {
    New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
}

$BatContent = "@echo off`r`nelixir `"%USERPROFILE%\lontar-aiel\scripts\calculate_emission.exs`" %*"
Set-Content -Path "$BIN_DIR\lontar.bat" -Value $BatContent

Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "🚀 Run 'lontar opt-in' to initialize the telemetry daemon."
