# Latest Ubuntu LTS
FROM ghcr.io/selkies-project/selkies-egl-desktop:26.04

ARG DEBIAN_FRONTEND=noninteractive

ENV WINEPREFIX="/home/ubuntu/.wineprefix-proton"
ENV WINEDEBUG="-all"
ENV PROTONPATH="GE-Proton"
ENV PROTON_NVIDIA_LIBS=1
ENV PROTON_NVIDIA_NVCUDA=1
ENV PROTON_NVIDIA_NVENC=1
ENV PROTON_FORCE_NVAPI=1
ENV DXVK_NVAPI_D3D12_NV_SHADER_EXTN=1

# Install all the required packages not included in base image
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections \
 && sudo apt update \
 && sudo apt install -y wget ca-certificates gnupg curl ubuntu-restricted-extras \
 && wget https://github.com/Open-Wine-Components/umu-launcher/releases/download/1.4.4/python3-umu-launcher_1.4.4-1_amd64_ubuntu-resolute.deb -O /tmp/umu.deb \
 && sudo apt install -y /tmp/umu.deb \
 && rm -f /tmp/umu.deb \
 && sudo apt autoremove -y \
 && sudo apt clean \
 && sudo rm -rf /var/lib/apt/lists/*

# Install MangoHud with NVIDIA support
RUN mkdir -p /home/ubuntu/mangohud-upstream \
 && wget -qO- https://github.com/flightlessmango/MangoHud/releases/download/v0.8.4/MangoHud-0.8.4.r0.g992103e.tar.gz \
  | tar -xz -C /home/ubuntu/mangohud-upstream --strip-components=1 \
 && cd /home/ubuntu/mangohud-upstream \
 && ./mangohud-setup.sh install \
 && cd /home/ubuntu \
 && rm -rf mangohud-upstream

# Copy MangoHud config
RUN mkdir -p /home/ubuntu/.config/MangoHud

COPY --chown=1000:1000 \
    mangohud/MangoHud.conf \
    /home/ubuntu/.config/MangoHud/MangoHud.conf

# Initialize wineprefix with GE-proton. Exit code 1 is expected since we are not running a game yet.
RUN umu-run "" || true

# Cleanup
RUN sudo apt autoremove -y
RUN sudo rm -rf /var/lib/apt/lists/*

# Sensible defaults
ENV NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    DISPLAY=:1

