#!/bin/bash
# ============================================================
# Roblox en Linux (Arch/Omarchy) via Sober — v2.0
# AMD Ryzen + Radeon Vega Integrada + Wayland/Hyprland
# Fix incluido: SDL_INIT_VIDEO / WAYLAND_DISPLAY propagation
# ============================================================

set -e

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
info() { echo -e "${CYAN}  → $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
err()  { echo -e "${RED}  ✗ $1${NC}"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Instalador de Roblox para Linux  v2.0     ║${NC}"
echo -e "${CYAN}║   Sober + Flatpak + AMD Vega + Hyprland     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── Detectar WAYLAND_DISPLAY real ───────────────────────────
WDISPLAY="${WAYLAND_DISPLAY:-}"
if [ -z "$WDISPLAY" ]; then
    # Intentar detectar automáticamente
    for candidate in wayland-0 wayland-1; do
        if [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$candidate" ]; then
            WDISPLAY="$candidate"
            break
        fi
    done
fi

if [ -z "$WDISPLAY" ]; then
    warn "No se pudo detectar WAYLAND_DISPLAY automáticamente."
    warn "Asegúrate de correr este script DENTRO de tu sesión Hyprland."
    warn "Usando 'wayland-1' como valor por defecto..."
    WDISPLAY="wayland-1"
else
    ok "WAYLAND_DISPLAY detectado: $WDISPLAY"
fi

# ── 1. Flatpak ───────────────────────────────────────────────
echo ""
echo "[1/6] Verificando Flatpak..."
if ! command -v flatpak &>/dev/null; then
    info "Instalando Flatpak..."
    sudo pacman -S --noconfirm flatpak
else
    ok "Flatpak ya instalado"
fi

# ── 2. Flathub ──────────────────────────────────────────────
echo "[2/6] Agregando repositorio Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
ok "Flathub listo"

# ── 3. Portal GTK (requerido por Hyprland para file picker) ─
echo "[3/6] Instalando xdg-desktop-portal-gtk..."
if ! pacman -Qi xdg-desktop-portal-gtk &>/dev/null; then
    sudo pacman -S --noconfirm xdg-desktop-portal-gtk
    ok "xdg-desktop-portal-gtk instalado"
else
    ok "xdg-desktop-portal-gtk ya instalado"
fi

# ── 4. Sober (Roblox) ───────────────────────────────────────
echo "[4/6] Instalando Sober (cliente Roblox para Linux)..."
flatpak install -y flathub org.vinegarhq.Sober
ok "Sober instalado"

# ── 5. Override Flatpak con variables correctas ─────────────
echo "[5/6] Configurando variables Wayland/AMD para Flatpak..."

OVERRIDE_DIR="$HOME/.local/share/flatpak/overrides"
mkdir -p "$OVERRIDE_DIR"

cat > "$OVERRIDE_DIR/org.vinegarhq.Sober" << OVERRIDE
[Context]
sockets=wayland;fallback-x11;

[Environment]
WAYLAND_DISPLAY=$WDISPLAY
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
MESA_GL_VERSION_OVERRIDE=4.6
OVERRIDE

# Permiso de input (necesario para teclado/mouse dentro del juego)
flatpak override --user \
    --filesystem=xdg-run/app/com.discordapp.Discord:create \
    --filesystem=xdg-run/discord-ipc-0 \
    --device=input \
    org.vinegarhq.Sober

ok "Variables AMD/Wayland configuradas (WAYLAND_DISPLAY=$WDISPLAY)"

# ── 6. Lanzador de escritorio ────────────────────────────────
echo "[6/6] Creando acceso directo..."

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/roblox-sober.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Roblox (Sober)
Comment=Roblox via Sober en Linux
Exec=flatpak run org.vinegarhq.Sober
Icon=org.vinegarhq.Sober
Terminal=false
Type=Application
Categories=Game;
DESKTOP

ok "Acceso directo creado"

# ── Matar procesos zombie por si acaso ───────────────────────
flatpak kill org.vinegarhq.Sober 2>/dev/null || true

# ── Listo ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         ¡Instalación completa! v2.0         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Para jugar Roblox corre:"
echo ""
echo -e "   ${CYAN}flatpak run org.vinegarhq.Sober${NC}"
echo ""
echo "O búscalo en tu menú como 'Roblox (Sober)'"
echo ""
echo -e "${YELLOW}NOTA: La primera vez descarga el APK de Roblox (~150MB),${NC}"
echo -e "${YELLOW}espera unos minutos. Necesitas internet estable.${NC}"
echo ""
echo -e "${YELLOW}Si hay problemas de DNS (el APK no descarga):${NC}"
echo -e "   sudo sh -c 'echo nameserver 1.1.1.1 > /etc/resolv.conf'"
echo ""
