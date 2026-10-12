FROM ps4all-base:latest

ENV WINEPREFIX="/home/ubuntu/arcware-prefix"
ENV WINEDEBUG="-all"
ENV PROTONPATH="GE-Proton"

# Initialize wineprefix with GE-proton. Exit code 1 is expected since we are not running a game yet.
RUN umu-run "" || true

# Copy MangoHud config
RUN mkdir -p /home/ubuntu/.config/MangoHud

COPY --chown=1000:1000 \
    mangohud/MangoHud.conf \
    /home/ubuntu/.config/MangoHud/MangoHud.conf

RUN chown -R 1000:1000 /home/ubuntu/

# Sensible defaults
ENV NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    DISPLAY=:1

