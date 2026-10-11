#!/usr/bin/env bash
# Turns a fresh Ubuntu 26.04 server into a ps4all machine: Selkies desktop on boot, Wine prefix, MangoHud.
# Mirrors Dockerfile.base + Dockerfile. Run as root from the repo root (so mangohud/MangoHud.conf is found).
#
#   sudo SELKIES_PASSWORD='secret' ./install_bare_metal.sh
#
# Optional variables: SELKIES_USER (ubuntu), SELKIES_PORT (8080), SELKIES_SESSION (lxqt),
#                     SELKIES_VERSION (latest release tag), WINEPREFIX_PATCH_URL.
set -euo pipefail

SELKIES_USER="${SELKIES_USER:-ubuntu}"
SELKIES_PORT="${SELKIES_PORT:-8080}"
SELKIES_SESSION="${SELKIES_SESSION:-lxqt}"
SELKIES_PASSWORD="${SELKIES_PASSWORD:-}"
SELKIES_VERSION="${SELKIES_VERSION:-}"
WINEPREFIX_PATCH_URL="${WINEPREFIX_PATCH_URL:-https://skipperro1.s3.eu-central-1.amazonaws.com/wineprefix-patch.zip}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

log() { printf '\n==> %s\n' "$*"; }

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

. /etc/os-release
if [ "${ID}" != "ubuntu" ] || [ "${VERSION_ID}" != "26.04" ]; then
    echo "WARNING: written for Ubuntu 26.04, found ${PRETTY_NAME:-unknown}" >&2
fi

case "${SELKIES_PASSWORD}" in
    *'"'* | *'\'* | *$'\n'*)
        echo "SELKIES_PASSWORD must not contain double quotes, backslashes or newlines" >&2
        exit 1
        ;;
esac

GENERATED_PASSWORD=0
if [ -z "${SELKIES_PASSWORD}" ]; then
    SELKIES_PASSWORD="$(openssl rand -hex 12)"
    GENERATED_PASSWORD=1
fi

# ---------------------------------------------------------------- packages
log "Enabling repositories and 32-bit architecture"
apt-get update
apt-get install -y software-properties-common wget curl jq ca-certificates gnupg unzip openssl
add-apt-repository -y universe
add-apt-repository -y multiverse
dpkg --add-architecture i386
apt-get update

log "Installing Wine, MangoHud and graphics runtime"
apt-get install -y wine winetricks cabextract mangohud xvfb xauth \
    mesa-vulkan-drivers libvulkan1 libvulkan1:i386 libgl1:i386 vulkan-tools

log "Installing codecs and fonts"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get install -y ubuntu-restricted-extras

log "Installing audio stack"
apt-get install -y --no-install-recommends pipewire pipewire-pulse pipewire-audio wireplumber pipewire-alsa \
    xdotool xclip x11-xserver-utils x11-utils wmctrl dbus-x11

log "Installing LXQt desktop"
apt-get install -y --no-install-recommends \
    lxqt-session lxqt-panel lxqt-runner lxqt-themes lxqt-config lxqt-qtplugin lxqt-notificationd \
    lxqt-policykit lxqt-menu-data lxqt-about openbox obconf-qt qterminal pcmanfm-qt lximage-qt \
    pavucontrol-qt xterm breeze-icon-theme adwaita-icon-theme gvfs gvfs-daemons libnotify-bin \
    qt6-svg-plugins qt6-image-formats-plugins kimageformat6-plugins gtk-update-icon-cache \
    fonts-dejavu-core fonts-liberation fonts-noto-core fonts-noto-color-emoji

# Without a configured theme lxqt-panel paints nothing (same fallback the Selkies desktop image uses).
first_installed() {
    local base="$1" name
    shift
    for name in "$@"; do
        if [ -d "${base}/${name}" ]; then
            printf '%s' "${name}"
            return
        fi
    done
}
ICON_THEME="$(first_installed /usr/share/icons breeze Adwaita hicolor)"
LXQT_THEME="$(first_installed /usr/share/lxqt/themes ambiance system light Leech)"
mkdir -p /etc/xdg/lxqt
printf '[General]\nicon_theme=%s\ntheme=%s\n' "${ICON_THEME}" "${LXQT_THEME}" > /etc/xdg/lxqt/lxqt.conf
printf 'TerminalEmulator=qterminal.desktop\n' > /etc/xdg/qtxdg.conf

# ---------------------------------------------------------------- Selkies
if [ -z "${SELKIES_VERSION}" ]; then
    log "Looking up the latest Selkies release"
    SELKIES_VERSION="$(curl -fsSL https://api.github.com/repos/selkies-project/selkies/releases/latest | jq -r '.tag_name')"
fi
log "Installing Selkies ${SELKIES_VERSION}"
DISTRO="${ID}$([ "${ID}" = "ubuntu" ] && echo "${VERSION_ID}" || echo "${VERSION_CODENAME}")"
PKG="selkies-${SELKIES_VERSION}-${DISTRO}-$(dpkg --print-architecture).deb"
TMP_DIR="$(mktemp -d)"
chmod 755 "${TMP_DIR}" # the service user reads the wineprefix patch from here
trap 'rm -rf "${TMP_DIR}"' EXIT
curl -fsSL -o "${TMP_DIR}/${PKG}" "https://github.com/selkies-project/selkies/releases/download/${SELKIES_VERSION}/${PKG}"
apt-get install -y "${TMP_DIR}/${PKG}"
SELKIES_SESSION_BIN="$(command -v selkies-session)"

# ---------------------------------------------------------------- user
if ! id "${SELKIES_USER}" > /dev/null 2>&1; then
    log "Creating user ${SELKIES_USER}"
    useradd -m -s /bin/bash "${SELKIES_USER}"
fi
for group in audio video render input; do
    getent group "${group}" > /dev/null && usermod -aG "${group}" "${SELKIES_USER}"
done
USER_HOME="$(getent passwd "${SELKIES_USER}" | cut -d: -f6)"
USER_GROUP="$(id -gn "${SELKIES_USER}")"

as_user() {
    runuser -u "${SELKIES_USER}" -- env HOME="${USER_HOME}" WINEPREFIX="${USER_HOME}/.wine" \
        WINEDLLOVERRIDES="mscoree,mshtml=" WINEDEBUG="-all" "$@"
}

# ---------------------------------------------------------------- Wine prefix
PREFIX="${USER_HOME}/.wine"
if [ ! -f "${PREFIX}/.ps4all_done" ]; then
    log "Creating Wine prefix"
    as_user xvfb-run -a wineboot -u
    as_user wineserver -w

    log "Applying wineprefix patch"
    curl -fsSL -o "${TMP_DIR}/wineprefix-patch.zip" "${WINEPREFIX_PATCH_URL}"
    as_user unzip -o "${TMP_DIR}/wineprefix-patch.zip" -d "${PREFIX}"
    as_user touch "${PREFIX}/.ps4all_done"
fi

log "Installing MangoHud config"
as_user mkdir -p "${USER_HOME}/.config/MangoHud"
if [ -f "${SCRIPT_DIR}/mangohud/MangoHud.conf" ]; then
    install -o "${SELKIES_USER}" -g "${USER_GROUP}" -m 644 "${SCRIPT_DIR}/mangohud/MangoHud.conf" \
        "${USER_HOME}/.config/MangoHud/MangoHud.conf"
else
    echo "mangohud/MangoHud.conf not found next to this script, skipping" >&2
fi

# Replaces the ./app volume mount of docker-compose.yml
as_user mkdir -p "${USER_HOME}/app"

# ---------------------------------------------------------------- service
log "Installing systemd service"
install -d -m 755 /etc/selkies
umask 077
cat > /etc/selkies/selkies.env << EOF
SELKIES_BASIC_AUTH_USER="${SELKIES_USER}"
SELKIES_BASIC_AUTH_PASSWORD="${SELKIES_PASSWORD}"
SELKIES_PORT="${SELKIES_PORT}"
SELKIES_ENABLE_HTTPS="true"
SELKIES_WAYLAND="false"
WINEPREFIX="${PREFIX}"
WINEDLLOVERRIDES="mscoree,mshtml="
WINEDEBUG="-all"
NVIDIA_DRIVER_CAPABILITIES="all"
NVIDIA_VISIBLE_DEVICES="all"
EOF
umask 022

cat > /etc/systemd/system/selkies.service << EOF
[Unit]
Description=Selkies remote desktop session (ps4all)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SELKIES_USER}
Group=${USER_GROUP}
WorkingDirectory=${USER_HOME}
EnvironmentFile=/etc/selkies/selkies.env
ExecStart=${SELKIES_SESSION_BIN} --session=${SELKIES_SESSION} --public
Restart=on-failure
RestartSec=5
KillMode=control-group
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now selkies.service

if command -v ufw > /dev/null && ufw status | grep -q '^Status: active'; then
    ufw allow "${SELKIES_PORT}/tcp"
fi

if ! command -v nvidia-smi > /dev/null; then
    echo
    echo "WARNING: no NVIDIA driver found. Install one (e.g. 'ubuntu-drivers install') and reboot for GPU encoding." >&2
fi

echo
echo "====================================================================="
echo "Done. Selkies is running as the 'selkies' service and starts on boot."
echo "Open:     https://<server-ip>:${SELKIES_PORT}  (self-signed certificate)"
echo "Login:    ${SELKIES_USER}"
if [ "${GENERATED_PASSWORD}" -eq 1 ]; then
    echo "Password: ${SELKIES_PASSWORD}  (generated, stored in /etc/selkies/selkies.env)"
else
    echo "Password: the one you passed in SELKIES_PASSWORD"
fi
echo "Put your Windows application in ${USER_HOME}/app"
echo "Logs:     journalctl -u selkies -f"
echo "====================================================================="
