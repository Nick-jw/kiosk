#!/bin/bash
set -e

echo "Setting up Raspberry Pi Kiosk"

# Configuration
REPO_URL="https://github.com/Nick-jw/kiosk.git"
BUILD_BRANCH="kiosk-build"
KIOSK_DIR="$HOME/kiosk-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log "Installing dependencies"
sudo apt update
sudo apt install -y git python3 unclutter

log "Creating kiosk runtime script"
cat > "$HOME/run-kiosk.sh" << "EOF"
#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/Nick-jw/kiosk.git"
BUILD_BRANCH="kiosk-build"
KIOSK_DIR="$HOME/kiosk-app"
LOG_FILE="/var/log/kiosk.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | sudo tee -a "$LOG_FILE"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - $1" | sudo tee -a "$LOG_FILE"
}

warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - $1" | sudo tee -a "$LOG_FILE"
}

log "Starting kiosk manager..."

# Handle repo clone / update
if [ ! -d "$KIOSK_DIR" ]; then
    log "Cloning kiosk repo for the first time"
    git clone -b "$BUILD_BRANCH" "$REPO_URL" "$KIOSK_DIR" || {
        error "Failed to clone kiosk repo"
        exit 1
    }
    log "Kiosk repo cloned successfully"
else
    log "Updating existing kiosk repo"
    cd "$KIOSK_DIR"
    if git pull origin "$BUILD_BRANCH"; then
        log "Update completed successfully"
    else
        warn "Git pull failed, using existing files"
    fi
fi

# Sanity check kiosk app exists
if [ ! -f "$KIOSK_DIR/index.html" ]; then
    error "Kiosk app index.html not found"
    exit 1
fi

# Display version info
if [ -f "$KIOSK_DIR/VERSION.txt" ]; then
    cat "$KIOSK_DIR/VERSION.txt"
fi

# Start X11
log "Starting X11..."
export DISPLAY=:0
startx /usr/bin/openbox-session &
X11_PID=$!

# Wait for X11 to start
sleep 5

# Start http server
log "Starting http server..."
cd "$KIOSK_DIR"
python3 -m http.server 8000 > /dev/null 2>&1 &
HTTP_PID=$!

# Wait for http server to start
sleep 5

# Hide cursor
unclutter -idle 1 > /dev/null 2>&1 &

# Start chromium in kiosk mode
log "Starting Chromium kiosk..."
chromium-browser \
    --kiosk \
    http://localhost:8000 &
CHROMIUM_PID=$!

log "Kiosk started (X11: $X11_PID, HTTP: $HTTP_PID, Chromium: $CHROMIUM_PID)"

# Wait for chromium to exit
wait $CHROMIUM_PID
log "Chromium exited"

# Cleanup
kill $HTTP_PID 2>/dev/null || true
kill $X11_PID 2>/dev/null || true

log "Kiosk stopped"
EOF

# Make runtime script executable
chmod +x "$HOME/run-kiosk.sh"

# Create systemd service
log "Creating systemd service..."
sudo tee /etc/systemd/system/kiosk.service > /dev/null << EOF
[Unit]
Description=Kiosk Service
After=network-online.target graphical-session.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=pi
Group=pi
Environment=HOME=/home/pi
Environment=DISPLAY=:0
ExecStart=/home/pi/run-kiosk.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=true
ProtectHome=true
ReadWritePaths=/home/pi /var/log

[Install]
WantedBy=multi-user.target
EOF

# Create log files
sudo touch /var/log/kiosk.log
sudo chown pi:pi /var/log/kiosk.log

# Create status script
log "Creating status script..."
cat > "$HOME/kiosk-status.sh" << "EOF"
#!/bin/bash
echo "=== Kiosk Status ==="
echo "Service Status:"
sudo systemctl status kiosk.service --no-pager -l

echo -e "\nVersion Info:"
if [ -f "$HOME/kiosk-app/VERSION" ]; then
    cat "$HOME/kiosk-app/VERSION"
else
    echo "No version info available"
fi

echo -e "\nRecent Logs:"
tail -20 /var/log/kiosk.log
EOF

chmod +x "$HOME/kiosk-status.sh"

# Enable service
log "Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable kiosk.service

echo "The kiosk service is now enabled and will auto-start on boot."
echo "Run 'sudo systemctl start kiosk.service' to start it now."