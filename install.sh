#!/usr/bin/env bash

# ==========================================================
# Conky Dashboard Installer
# Author: Aswin A
# ==========================================================

set -e

echo "-----------------------------------------"
echo " Installing Conky Dashboard"
echo "-----------------------------------------"

# ------------------------------
# 1. Check OS
# ------------------------------
if ! command -v apt &> /dev/null; then
    echo "This installer currently supports Debian/Ubuntu systems."
    exit 1
fi

# ------------------------------
# 2. Install Dependencies
# ------------------------------
echo "[+] Installing dependencies..."
sudo apt update
sudo apt install -y conky-all lm-sensors xdotool playerctl curl

# ------------------------------
# 3. Detect Network Interface
# ------------------------------
echo "[+] Detecting active network interface..."

NET_IFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

if [ -z "$NET_IFACE" ]; then
    echo "Could not detect interface. Defaulting to wlp2s0"
    NET_IFACE="wlp2s0"
fi

echo "    -> Using interface: $NET_IFACE"

# ------------------------------
# 4. Detect Battery
# ------------------------------
echo "[+] Detecting battery..."

BATTERY=$(ls /sys/class/power_supply/ | grep BAT | head -n1)

if [ -z "$BATTERY" ]; then
    echo "No battery detected. Skipping battery config."
else
    echo "    -> Battery detected: $BATTERY"
fi

# ------------------------------
# 5. Create Conky Directory
# ------------------------------
mkdir -p "$HOME/.config/conky"

# ------------------------------
# 6. Copy Config Files
# ------------------------------
echo "[+] Copying configuration files..."

if [ ! -f left.conf ] || [ ! -f right.conf ]; then
    echo "left.conf and right.conf must be in the same directory as this script."
    exit 1
fi

cp left.conf "$HOME/.config/conky/"
cp right.conf "$HOME/.config/conky/"

# ------------------------------
# 7. Replace Network Interface
# ------------------------------
echo "[+] Applying network interface..."

sed -i "s/wlp2s0/$NET_IFACE/g" "$HOME/.config/conky/left.conf"
sed -i "s/wlp2s0/$NET_IFACE/g" "$HOME/.config/conky/right.conf"

# ------------------------------
# 8. Replace Battery Name (if exists)
# ------------------------------
if [ -n "$BATTERY" ]; then
    sed -i "s/BAT0/$BATTERY/g" "$HOME/.config/conky/left.conf"
    sed -i "s/BAT0/$BATTERY/g" "$HOME/.config/conky/right.conf"
fi

# ------------------------------
# 9. Create Autostart Entry
# ------------------------------
echo "[+] Creating GNOME autostart entry..."

mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/conky-dashboard.desktop" <<EOL
[Desktop Entry]
Type=Application
Name=Conky Dashboard
Exec=sh -c "sleep 10 && conky -c $HOME/.config/conky/left.conf & conky -c $HOME/.config/conky/right.conf"
X-GNOME-Autostart-enabled=true
EOL

# ------------------------------
# 10. Wayland Warning
# ------------------------------
SESSION_TYPE=$(echo $XDG_SESSION_TYPE)

if [ "$SESSION_TYPE" = "wayland" ]; then
    echo ""
    echo "⚠ WARNING: You are using Wayland."
    echo "Conky works more reliably on Xorg."
    echo "If widgets do not appear after reboot,"
    echo "log out and choose 'Ubuntu on Xorg'."
    echo ""
fi

# ------------------------------
# 11. Restart Conky
# ------------------------------
echo "[+] Restarting Conky..."

killall conky 2>/dev/null || true

conky -c "$HOME/.config/conky/left.conf" &
conky -c "$HOME/.config/conky/right.conf" &

echo ""
echo "-----------------------------------------"
echo " Installation Complete!"
echo " Conky Dashboard is now running."
echo "-----------------------------------------"