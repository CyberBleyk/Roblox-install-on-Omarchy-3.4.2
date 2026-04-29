#!/usr/bin/env bash

set -e

echo "== Roblox Linux Installer v4.0 (Universal) =="

# -------------------------------
# Detectar distro
# -------------------------------
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "[ERROR] No se pudo detectar la distro"
    exit 1
fi

echo "[INFO] Distro detectada: $DISTRO"

# -------------------------------
# Detectar desktop
# -------------------------------
DESKTOP=${XDG_CURRENT_DESKTOP:-unknown}

if [[ "$DESKTOP" == *"Hyprland"* ]]; then
    PORTAL="xdg-desktop-portal-gtk"
    DESKTOP_ENV="Hyprland"
elif [[ "$DESKTOP" == *"KDE"* ]]; then
    PORTAL="xdg-desktop-portal-kde"
    DESKTOP_ENV="KDE"
elif [[ "$DESKTOP" == *"GNOME"* ]]; then
    PORTAL="xdg-desktop-portal-gnome"
    DESKTOP_ENV="GNOME"
else
    PORTAL="xdg-desktop-portal-gtk"
    DESKTOP_ENV="Unknown"
fi

echo "[INFO] Desktop: $DESKTOP_ENV"

# -------------------------------
# Instalar dependencias por distro
# -------------------------------
install_deps() {
    case "$DISTRO" in
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm flatpak $PORTAL
            ;;
        ubuntu|debian|kali)
            sudo apt update
            sudo apt install -y flatpak $PORTAL
            ;;
        fedora)
            sudo dnf install -y flatpak $PORTAL
            ;;
        nixos)
            echo "[WARN] NixOS detectado"
            echo "Agrega esto a configuration.nix:"
            echo "services.flatpak.enable = true;"
            echo "xdg.portal.enable = true;"
            echo "xdg.portal.extraPortals = [ pkgs.$PORTAL ];"
            exit 1
            ;;
        *)
            echo "[ERROR] Distro no soportada aún"
            exit 1
            ;;
    esac
}

install_deps

# -------------------------------
# Flatpak config
# -------------------------------
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -------------------------------
# Instalar Sober
# -------------------------------
flatpak install -y flathub org.vinegarhq.Sober

# -------------------------------
# Detectar Wayland
# -------------------------------
WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR" | grep wayland | head -n1)

if [[ -z "$WAYLAND_DISPLAY" ]]; then
    echo "[WARN] Wayland no detectado, usando fallback X11"
    WAYLAND_DISPLAY=""
fi

# -------------------------------
# Detectar GPU
# -------------------------------
GPU_INFO=$(lspci 2>/dev/null | grep -E "VGA|3D" || true)

if echo "$GPU_INFO" | grep -qi amd; then
    GPU="AMD"
elif echo "$GPU_INFO" | grep -qi nvidia; then
    GPU="NVIDIA"
elif echo "$GPU_INFO" | grep -qi intel; then
    GPU="INTEL"
else
    GPU="UNKNOWN"
fi

echo "[INFO] GPU: $GPU"

# -------------------------------
# Variables entorno
# -------------------------------
ENV_VARS="XDG_CURRENT_DESKTOP=$DESKTOP_ENV
XDG_SESSION_TYPE=wayland
SDL_VIDEODRIVER=wayland
GDK_SCALE=1
GDK_DPI_SCALE=1
SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0
MESA_GL_VERSION_OVERRIDE=4.6"

if [[ -n "$WAYLAND_DISPLAY" ]]; then
    ENV_VARS="WAYLAND_DISPLAY=$WAYLAND_DISPLAY
$ENV_VARS"
fi

if [[ "$GPU" == "NVIDIA" ]]; then
    ENV_VARS="$ENV_VARS
__GLX_VENDOR_LIBRARY_NAME=nvidia"
fi

# -------------------------------
# Override
# -------------------------------
OVERRIDE_FILE="$HOME/.local/share/flatpak/overrides/org.vinegarhq.Sober"
mkdir -p "$(dirname "$OVERRIDE_FILE")"

cat > "$OVERRIDE_FILE" <<EOF
[Context]
sockets=wayland;fallback-x11;

[Environment]
$ENV_VARS
EOF

echo "[OK] Override aplicado"

# -------------------------------
# Permisos
# -------------------------------
flatpak override --user \
    --filesystem=xdg-run/app/com.discordapp.Discord:create \
    --filesystem=xdg-run/discord-ipc-0 \
    --device=input \
    org.vinegarhq.Sober

# -------------------------------
# Desktop entry
# -------------------------------
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/roblox-sober.desktop <<EOF
[Desktop Entry]
Name=Roblox (Sober)
Exec=flatpak run org.vinegarhq.Sober
Type=Application
Categories=Game;
EOF

echo ""
echo "✅ Instalación completada en $DISTRO"
echo "Ejecuta: flatpak run org.vinegarhq.Sober"
