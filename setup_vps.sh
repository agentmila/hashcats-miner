#!/bin/bash
# ============================================================
# Hashcats.fun GPU Miner — VPS Setup & Run
# ============================================================
# This script sets up everything on a fresh Ubuntu GPU VPS.
# Run via SSH: ssh root@vps 'bash -s' < setup_vps.sh
# ============================================================
set -e

echo "=== Hashcats GPU Miner Setup ==="

# 1. System deps
echo "[1/5] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq nodejs npm git

# Check Node version (need >= 18 for native WebGPU)
NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VER" -lt 18 ]; then
    echo "  Node too old, installing v20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
fi
echo "  Node: $(node -v)"

# 2. Create directory
echo "[2/5] Creating miner directory..."
mkdir -p ~/hashcats-miner
cd ~/hashcats-miner

# 3. Copy files (or download if not present)
echo "[3/5] Setting up files..."
if [ ! -f miner.mjs ]; then
    echo "  ERROR: miner.mjs not found!"
    echo "  Copy miner.mjs and package.json to ~/hashcats-miner/ first."
    exit 1
fi

# 4. Install npm deps
echo "[4/5] Installing npm dependencies..."
npm install

# 5. Verify GPU
echo "[5/5] Checking GPU..."
nvidia-smi 2>/dev/null || echo "  WARNING: nvidia-smi not found. GPU mining may not work."

echo ""
echo "=== Setup complete! ==="
echo ""
echo "To start mining:"
echo "  cd ~/hashcats-miner"
echo "  node miner.mjs --key 0xYOUR_PRIVATE_KEY"
echo ""
echo "Dry run (no TX submit):"
echo "  node miner.mjs --key 0xYOUR_PRIVATE_KEY --dry-run"
echo ""
echo "CPU only (no GPU):"
echo "  node miner.mjs --key 0xYOUR_PRIVATE_KEY --cpu-only"
echo ""
echo "With screen for persistence:"
echo "  screen -S hashcats"
echo "  node miner.mjs --key 0xYOUR_PRIVATE_KEY"
echo "  # Ctrl+A D to detach, screen -r hashcats to reattach"
echo ""
echo "With tmux:"
echo "  tmux new -s hashcats 'node miner.mjs --key 0xYOUR_PRIVATE_KEY'"
