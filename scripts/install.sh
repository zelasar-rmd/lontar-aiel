#!/usr/bin/env bash
# Lontar AIEL Universal Installer (Linux/macOS/Termux)

set -e

echo "⚡ Installing Lontar AIEL CLI & Background Telemetry..."

# Check Elixir
if ! command -v elixir &> /dev/null; then
    echo "⚠️  Elixir is not installed."
    echo "Please install Elixir (e.g., 'pkg install elixir', 'sudo apt install elixir', or 'brew install elixir') and run this script again."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "⚠️  Git is not installed."
    echo "Please install Git and run this script again."
    exit 1
fi

DEST_DIR="$HOME/.local/share/lontar-aiel"
BIN_DIR="$HOME/.local/bin"

if [ -d "$DEST_DIR" ]; then
    echo "🔄 Updating existing installation at $DEST_DIR..."
    git -C "$DEST_DIR" fetch --all
    git -C "$DEST_DIR" checkout confluent-alpha
    git -C "$DEST_DIR" pull origin confluent-alpha
else
    echo "📥 Cloning Lontar AIEL repository to $DEST_DIR..."
    mkdir -p "$(dirname "$DEST_DIR")"
    git clone -b confluent-alpha https://github.com/zelasar-rmd/lontar-aiel.git "$DEST_DIR"
fi

echo "⚙️  Setting up CLI alias 'lontar'..."
mkdir -p "$BIN_DIR"
cat << 'EOF' > "$BIN_DIR/lontar"
#!/usr/bin/env bash
elixir "$HOME/.local/share/lontar-aiel/scripts/calculate_emission.exs" "$@"
EOF
chmod +x "$BIN_DIR/lontar"

# Export PATH note for interactive shells
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ] && [ -w "$PREFIX/bin" ]; then
    cp "$BIN_DIR/lontar" "$PREFIX/bin/lontar" 2>/dev/null || true
elif [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    mkdir -p "$HOME/bin"
    cp "$BIN_DIR/lontar" "$HOME/bin/lontar" 2>/dev/null || true
    echo "⚠️  Please ensure $HOME/bin or $BIN_DIR is in your PATH."
fi

# Setup autostart in shell profile
echo "⚡ Setting up automatic background telemetry daemon..."
SCRIPT_PATH="$DEST_DIR/scripts/lontar_telemetry_daemon.exs"
AUTOSTART_MARKER="# Lontar AIEL Auto-Start"

for PROF in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$PROF" ] || [ "$PROF" = "$HOME/.bashrc" ]; then
        if ! grep -q "$AUTOSTART_MARKER" "$PROF" 2>/dev/null; then
            echo "" >> "$PROF"
            echo "$AUTOSTART_MARKER" >> "$PROF"
            echo "if ! pgrep -f 'lontar_telemetry_daemon.exs' > /dev/null; then" >> "$PROF"
            echo "    nohup elixir \"$SCRIPT_PATH\" > /dev/null 2>&1 &" >> "$PROF"
            echo "fi" >> "$PROF"
        fi
    fi
done

# Start background daemon immediately
if ! pgrep -f 'lontar_telemetry_daemon.exs' > /dev/null; then
    nohup elixir "$SCRIPT_PATH" > /dev/null 2>&1 &
fi

echo "✅ Installation complete!"
echo ""
echo "📜 Displaying Lontar AIEL Privacy & Opt-In Protocol:"
"$BIN_DIR/lontar" opt-in
