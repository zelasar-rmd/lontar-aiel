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
Write-Host ""
Write-Host "📜 Displaying Lontar AIEL Privacy & Opt-In Protocol:" -ForegroundColor Cyan
& "$BIN_DIR\lontar.bat" opt-in

Write-Host "? Setting up automatic background telemetry daemon..." -ForegroundColor Cyan
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$VbsPath = "$StartupFolder\LontarTelemetryDaemon.vbs"
$VbsContent = "Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "elixir "" " & WshShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\lontar-aiel\scripts\lontar_telemetry_daemon.exs"", 0"
Set-Content -Path $VbsPath -Value $VbsContent
Start-Process -FilePath "elixir" -ArgumentList ""$DEST_DIR\scripts\lontar_telemetry_daemon.exs"" -WindowStyle Hidden -ErrorAction SilentlyContinue
