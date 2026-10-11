FROM ps4all-base:latest

# Wineprefix is created on first start by create_wineprefix.sh (autostart)
RUN rm -rf /home/ubuntu/.wine && mkdir -p /home/ubuntu/.wine && chown 1000:1000 /home/ubuntu/.wine

RUN wineboot -u
RUN wineserver -w

# Copy wineprefix-patch and extract it to wineprefix, overwriting existing files
RUN wget -O /home/ubuntu/wineprefix-patch.zip https://skipperro1.s3.eu-central-1.amazonaws.com/wineprefix-patch.zip
RUN unzip -o /home/ubuntu/wineprefix-patch.zip -d /home/ubuntu/.wine
RUN rm /home/ubuntu/wineprefix-patch.zip

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

