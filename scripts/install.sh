#!/usr/bin/env bash
# Lontar AIEL: Universal Linux/macOS Installation Script
# Document Version: v0.1.0-alpha.2026-09-22-19:00

set -e

echo "📦 Welcome to Lontar AIEL Zero-Friction Setup!"
echo "─────────────────────────────────────────────────────────"

# 1. Dependency Checks
command -v git >/dev/null 2>&1 || { echo >&2 "❌ Git is required but it's not installed. Aborting."; exit 1; }
command -v elixir >/dev/null 2>&1 || { 
  echo >&2 "❌ Elixir is required but it's not installed."
  echo >&2 "👉 Install it via your package manager (e.g., 'sudo apt install elixir' or 'brew install elixir')."
  exit 1; 
}

# 2. Setup Directories
INSTALL_DIR="${HOME}/.local/share/lontar-aiel"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# 3. Clone or Update Repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "🔄 Updating existing Lontar AIEL installation..."
    cd "$INSTALL_DIR"
    git fetch
    git checkout confluent-alpha 2>/dev/null || git checkout main
    git pull origin confluent-alpha 2>/dev/null || git pull origin main
    cd - > /dev/null
else
    echo "📥 Downloading Lontar AIEL..."
    git clone --branch confluent-alpha https://github.com/zelasar-rmd/lontar-aiel.git "$INSTALL_DIR" || \
    git clone https://github.com/zelasar-rmd/lontar-aiel.git "$INSTALL_DIR"
fi

# 4. Create Executable Wrapper
echo "⚙️ Creating 'lontar' CLI wrapper..."
cat << 'EOF' > "$BIN_DIR/lontar"
#!/usr/bin/env bash
elixir "${HOME}/.local/share/lontar-aiel/scripts/calculate_emission.exs" "$@"
EOF
chmod +x "$BIN_DIR/lontar"

# 5. Path setup instructions
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "⚠️  NOTE: '$BIN_DIR' is not in your PATH."
    echo "👉 Please add this line to your ~/.bashrc or ~/.zshrc:"
    echo '   export PATH="$HOME/.local/bin:$PATH"'
    echo "   Then restart your terminal or run: source ~/.bashrc"
    
    export PATH="$BIN_DIR:$PATH"
fi

echo "─────────────────────────────────────────────────────────"
echo "✅ Installation Complete!"
echo "🚀 Initializing Lontar AIEL and reviewing Privacy Protocol..."
echo ""

# 6. Trigger initial opt-in
"$BIN_DIR/lontar" opt-in
