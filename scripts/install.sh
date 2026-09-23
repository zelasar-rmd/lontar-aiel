#!/usr/bin/env bash
# Lontar AIEL Universal Installer (Linux/macOS)

set -e

echo "📦 Installing Lontar AIEL CLI..."

# Check Elixir
if ! command -v elixir &> /dev/null; then
    echo "⚠️  Elixir is not installed."
    echo "Please install Elixir (e.g., 'sudo apt install elixir' or 'brew install elixir') and run this script again."
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

# Export PATH note
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "⚠️  Please add $BIN_DIR to your PATH by adding the following to your shell profile (.bashrc / .zshrc):"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "✅ Installation complete!"
echo ""
echo "📜 Displaying Lontar AIEL Privacy & Opt-In Protocol:"
"$BIN_DIR/lontar" opt-in

