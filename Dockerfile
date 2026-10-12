FROM ps4all-base:latest

ENV WINEPREFIX="/home/ubuntu/.wineprefix-proton"
ENV WINEDEBUG="-all"
ENV PROTONPATH="GE-Proton"

# Copy MangoHud config
RUN mkdir -p /home/ubuntu/.config/MangoHud

COPY --chown=1000:1000 \
    mangohud/MangoHud.conf \
    /home/ubuntu/.config/MangoHud/MangoHud.conf

RUN chown -R 1000:1000 /home/ubuntu/

# Install umu run and GE-proton
RUN wget \
  https://github.com/Open-Wine-Components/umu-launcher/releases/download/1.4.4/python3-umu-launcher_1.4.4-1_amd64_ubuntu-resolute.deb \
  -O /tmp/umu.deb

RUN sudo apt update
RUN sudo apt install -y /tmp/umu.deb
RUN rm -f /tmp/umu.deb
RUN sudo rm -rf /var/lib/apt/lists/*

# Initialize wineprefix with GE-proton. Exit code 1 is expected since we are not running a game yet.
RUN umu-run "" || true

# Sensible defaults
ENV NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    DISPLAY=:1

