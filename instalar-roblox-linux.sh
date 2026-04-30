#!/usr/bin/env bash
# ================================================================
#  Roblox en Linux via Sober — v4.0 STABLEE
#  Multi-distro | Smart GPU | Wayland/X11 Fallback | Self-healing
#
#  Uso:
#    bash <(curl -fsSL https://raw.githubusercontent.com/CyberBleyk/Roblox-install-on-Omarchy-3.4.2/main/instalar-roblox-linux.sh)
#
#  Con debug:
#    bash <(curl -fsSL ...) --debug
#
#  Repo: github.com/CyberBleyk/Roblox-install-on-Omarchy-3.4.2
#  Probado en: Omarchy 3.4.2 | Arch | Hyprland | AMD Vega iGPU
# ================================================================

set -euo pipefail

# ── Flags ────────────────────────────────────────────────────
DEBUG=0
[[ "${1:-}" == "--debug" ]] && DEBUG=1

# ── Log file ─────────────────────────────────────────────────
LOG_FILE="/tmp/roblox-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

ok()    { echo -e "${GREEN}  ✓ $1${NC}"; }
info()  { echo -e "${CYAN}  → $1${NC}"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${NC}"; }
err()   { echo -e "${RED}  ✗ ERROR: $1${NC}"; echo "  Log: $LOG_FILE"; exit 1; }
debug() { [[ $DEBUG -eq 1 ]] && echo -e "  [DBG] $1" || true; }
step()  { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        Roblox Linux Installer  v4.0  STABLE         ║${NC}"
echo -e "${CYAN}║   Multi-distro · Smart GPU · Wayland/X11 Fallback   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
[[ $DEBUG -eq 1 ]] && echo -e "  ${YELLOW}[MODO DEBUG ACTIVO] Log: $LOG_FILE${NC}"
echo ""

# ================================================================
# 1. DISTRO
# ================================================================
step "1/10  Detectando sistema"
[ -f /etc/os-release ] && . /etc/os-release || err "No se pudo detectar la distro"
DISTRO="${ID:-unknown}"
DISTRO_VERSION="${VERSION_ID:-?}"
ok "Distro: $DISTRO $DISTRO_VERSION"

# ================================================================
# 2. DESKTOP Y PORTAL
# ================================================================
step "2/10  Detectando entorno gráfico"
DESKTOP_RAW="${XDG_CURRENT_DESKTOP:-unknown}"

if   [[ "$DESKTOP_RAW" == *"Hyprland"* ]]; then DE="Hyprland"; PORTAL="xdg-desktop-portal-gtk"
elif [[ "$DESKTOP_RAW" == *"sway"*     ]]; then DE="sway";     PORTAL="xdg-desktop-portal-gtk"
elif [[ "$DESKTOP_RAW" == *"KDE"*      ]]; then DE="KDE";      PORTAL="xdg-desktop-portal-kde"
elif [[ "$DESKTOP_RAW" == *"GNOME"*    ]]; then DE="GNOME";    PORTAL="xdg-desktop-portal-gnome"
else                                            DE="Unknown";   PORTAL="xdg-desktop-portal-gtk"
fi
ok "Desktop: $DE  |  Portal: $PORTAL"
debug "XDG_CURRENT_DESKTOP raw: $DESKTOP_RAW"

# ================================================================
# 3. GPU — 3 métodos en cascada, sin depender de lspci
# ================================================================
step "3/10  Detectando GPU"
GPU="UNKNOWN"; DRIVER="auto"

# Método 1: /sys/class/drm (siempre disponible)
for vendor_file in /sys/class/drm/*/device/vendor; do
    [ -f "$vendor_file" ] || continue
    VID=$(cat "$vendor_file" 2>/dev/null || true)
    debug "DRM vendor: $VID"
    case "$VID" in
        0x1002) GPU="AMD";    DRIVER="radeonsi"; break ;;
        0x8086) GPU="INTEL";  DRIVER="iris";     break ;;
        0x10de) GPU="NVIDIA"; DRIVER="nvidia";   break ;;
    esac
done

# Método 2: lspci fallback
if [[ "$GPU" == "UNKNOWN" ]] && command -v lspci &>/dev/null; then
    GPU_INFO=$(lspci 2>/dev/null | grep -E "VGA|3D|Display" || true)
    debug "lspci: $GPU_INFO"
    if   echo "$GPU_INFO" | grep -qi "amd\|radeon\|amdgpu"; then GPU="AMD";    DRIVER="radeonsi"
    elif echo "$GPU_INFO" | grep -qi "intel";                then GPU="INTEL";  DRIVER="iris"
    elif echo "$GPU_INFO" | grep -qi "nvidia";               then GPU="NVIDIA"; DRIVER="nvidia"
    fi
fi

# Método 3: CPU vendor (iGPU)
if [[ "$GPU" == "UNKNOWN" ]]; then
    CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo 2>/dev/null | awk '{print $3}' || true)
    debug "CPU vendor: $CPU_VENDOR"
    if   [[ "$CPU_VENDOR" == *"AMD"*   ]]; then GPU="AMD (iGPU)";   DRIVER="radeonsi"
    elif [[ "$CPU_VENDOR" == *"Intel"* ]]; then GPU="INTEL (iGPU)"; DRIVER="iris"
    fi
fi

ok "GPU: $GPU  |  Driver: $DRIVER"
[[ "$GPU" == "NVIDIA" ]] && warn "NVIDIA detectada — soporte experimental. Fallback X11 disponible si falla Wayland."

# ================================================================
# 4. WAYLAND — detección + fallback automático
# ================================================================
step "4/10  Detectando display server"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WDISPLAY=""; USE_WAYLAND=0

for candidate in wayland-1 wayland-0; do
    if [ -S "$RUNTIME_DIR/$candidate" ]; then
        WDISPLAY="$candidate"; USE_WAYLAND=1; break
    fi
done

[[ -z "$WDISPLAY" && -n "${WAYLAND_DISPLAY:-}" ]] && WDISPLAY="$WAYLAND_DISPLAY" && USE_WAYLAND=1

if [[ $USE_WAYLAND -eq 1 ]]; then
    ok "Wayland: $WDISPLAY"
else
    warn "Wayland no disponible — usando X11 como fallback"
fi
debug "RUNTIME_DIR: $RUNTIME_DIR | WDISPLAY: ${WDISPLAY:-none}"

# ================================================================
# 5. INSTALAR DEPENDENCIAS
# ================================================================
step "5/10  Instalando dependencias del sistema"

case "$DISTRO" in
    arch|manjaro|endeavouros|garuda|cachyos|artix)
        sudo pacman -S --noconfirm --needed flatpak "$PORTAL" ;;
    ubuntu|debian|pop|linuxmint|kali|elementary)
        sudo apt-get update -qq && sudo apt-get install -y flatpak "$PORTAL" ;;
    fedora)
        sudo dnf install -y flatpak "$PORTAL" ;;
    opensuse*|sled|sles)
        sudo zypper install -y flatpak "$PORTAL" ;;
    nixos)
        err "NixOS no soportado automáticamente.\nAgrega a configuration.nix:\n  services.flatpak.enable = true;\n  xdg.portal.enable = true;" ;;
    *)
        warn "Distro '$DISTRO' no reconocida — intentando genérico..."
        if   command -v apt-get &>/dev/null; then sudo apt-get install -y flatpak "$PORTAL"
        elif command -v dnf     &>/dev/null; then sudo dnf install -y flatpak "$PORTAL"
        elif command -v pacman  &>/dev/null; then sudo pacman -S --noconfirm --needed flatpak "$PORTAL"
        else err "No se encontró gestor de paquetes. Instala flatpak y $PORTAL manualmente."
        fi ;;
esac
ok "Dependencias del sistema OK"

# ================================================================
# 6. FLATPAK + FLATHUB
# ================================================================
step "6/10  Configurando Flatpak"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak kill org.vinegarhq.Sober 2>/dev/null && warn "Instancia zombie eliminada" || true
flatpak uninstall --unused -y 2>/dev/null || true
ok "Flatpak y Flathub listos"

# ================================================================
# 7. RUNTIME GL EXPLÍCITO (previene eglCreateContext failed)
# ================================================================
step "7/10  Instalando runtime GL"

RUNTIME_VER=""
for v in 24.08 23.08; do
    if flatpak remote-info flathub "org.freedesktop.Platform//$v" &>/dev/null 2>&1; then
        RUNTIME_VER="$v"; break
    fi
done

if [ -n "$RUNTIME_VER" ]; then
    flatpak install -y flathub "org.freedesktop.Platform//$RUNTIME_VER"           2>/dev/null || true
    flatpak install -y flathub "org.freedesktop.Platform.GL.default//$RUNTIME_VER" 2>/dev/null || true
    ok "Runtime GL $RUNTIME_VER instalado"
else
    warn "Runtime no verificado remotamente — Sober lo gestionará al primer inicio"
fi

# ================================================================
# 8. INSTALAR SOBER
# ================================================================
step "8/10  Instalando Sober"
flatpak install -y flathub org.vinegarhq.Sober
ok "Sober instalado"

# ================================================================
# 9. OVERRIDE DE FLATPAK
# ================================================================
step "9/10  Aplicando configuración de entorno"

declare -A EVAR
# Base
EVAR[GDK_SCALE]="1"
EVAR[LIBGL_ALWAYS_SOFTWARE]="0"
EVAR[MESA_GL_VERSION_OVERRIDE]="4.6"
EVAR[SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS]="0"
EVAR[XDG_CURRENT_DESKTOP]="$DE"

# Display
if [[ $USE_WAYLAND -eq 1 ]]; then
    EVAR[SDL_VIDEODRIVER]="wayland"
    EVAR[WAYLAND_DISPLAY]="$WDISPLAY"
    EVAR[XDG_SESSION_TYPE]="wayland"
else
    EVAR[SDL_VIDEODRIVER]="x11"
    EVAR[XDG_SESSION_TYPE]="x11"
fi

# GPU-específicas
case "$GPU" in
    AMD*)
        # iGPU AMD: NO forzar GBM_BACKEND — provoca EGL failure en Vega
        EVAR[MESA_LOADER_DRIVER_OVERRIDE]="radeonsi"
        EVAR[__GLX_VENDOR_LIBRARY_NAME]="mesa"
        ;;
    INTEL*)
        EVAR[MESA_LOADER_DRIVER_OVERRIDE]="iris"
        EVAR[__GLX_VENDOR_LIBRARY_NAME]="mesa"
        ;;
    NVIDIA*)
        EVAR[__GLX_VENDOR_LIBRARY_NAME]="nvidia"
        # GBM solo si nvidia_drm está cargado
        if lsmod 2>/dev/null | grep -q "nvidia_drm"; then
            EVAR[GBM_BACKEND]="nvidia-drm"
            EVAR[__NV_PRIME_RENDER_OFFLOAD]="1"
            debug "nvidia_drm activo — GBM_BACKEND habilitado"
        else
            warn "nvidia_drm no detectado — omitiendo GBM_BACKEND"
        fi
        ;;
    *)
        warn "GPU desconocida — variables mínimas"
        ;;
esac

# Escribir override con variables ordenadas alfabéticamente
OVERRIDE_FILE="$HOME/.local/share/flatpak/overrides/org.vinegarhq.Sober"
mkdir -p "$(dirname "$OVERRIDE_FILE")"

ENV_SECTION=$(for key in $(echo "${!EVAR[@]}" | tr ' ' '\n' | sort); do
    echo "$key=${EVAR[$key]}"
done)

cat > "$OVERRIDE_FILE" << OVERRIDE
[Context]
sockets=wayland;fallback-x11;
devices=input;
filesystems=xdg-run/app/com.discordapp.Discord:create;xdg-run/discord-ipc-0;

[Environment]
$ENV_SECTION
OVERRIDE

ok "Override aplicado"
if [[ $DEBUG -eq 1 ]]; then
    echo "  Contenido:"
    cat "$OVERRIDE_FILE" | sed 's/^/    /'
fi

# ================================================================
# 10. TEST GL + ACCESO DIRECTO
# ================================================================
step "10/10  Verificación final"

# Test GL dentro del sandbox (best-effort, no bloquea)
GL_OK=0
if flatpak run --command=sh org.vinegarhq.Sober \
    -c "command -v glxinfo &>/dev/null && glxinfo 2>/dev/null | grep -i renderer" \
    > /tmp/gl_test.txt 2>&1; then
    GL_RENDERER=$(grep -i renderer /tmp/gl_test.txt | head -1 || true)
    [[ -n "$GL_RENDERER" ]] && GL_OK=1 && ok "OpenGL: $GL_RENDERER"
fi
[[ $GL_OK -eq 0 ]] && warn "Test GL no disponible en sandbox (normal — Sober usa su propio EGL)"

# Acceso directo
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

# ================================================================
# RESUMEN
# ================================================================
echo ""
echo -e "${CYAN}══════════════════ RESUMEN ══════════════════${NC}"
printf "  %-18s %s\n" "Distro:"     "$DISTRO $DISTRO_VERSION"
printf "  %-18s %s\n" "Desktop:"    "$DE"
printf "  %-18s %s\n" "GPU:"        "$GPU"
printf "  %-18s %s\n" "Driver:"     "$DRIVER"
printf "  %-18s %s\n" "Display:"    "${WDISPLAY:-X11 fallback}"
printf "  %-18s %s\n" "Runtime GL:" "${RUNTIME_VER:-auto}"
printf "  %-18s %s\n" "OpenGL:"     "$([[ $GL_OK -eq 1 ]] && echo 'Verificado ✓' || echo 'No verificado (normal)')"
printf "  %-18s %s\n" "Log:"        "$LOG_FILE"
echo -e "${CYAN}═════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅  Instalación completa              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Lanza Roblox:${NC}"
echo -e "     ${CYAN}flatpak run org.vinegarhq.Sober${NC}"
echo ""
echo -e "  ${YELLOW}Primera vez: descarga APK (~150MB) — espera unos minutos${NC}"
echo -e "  ${YELLOW}DNS fix si el APK no descarga:${NC}"
echo -e "     sudo sh -c 'echo nameserver 1.1.1.1 > /etc/resolv.conf'"
echo ""
echo -e "  ${YELLOW}Modo debug para reportar problemas:${NC}"
echo -e "     bash <(curl -fsSL <URL>) --debug"
echo -e "     Log guardado en: $LOG_FILE"
echo ""
