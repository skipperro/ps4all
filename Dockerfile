FROM ps4all-base:latest

# Wineprefix is created on first start by create_wineprefix.sh (autostart)
RUN rm -rf /home/ubuntu/.wine && mkdir -p /home/ubuntu/.wine && chown 1000:1000 /home/ubuntu/.wine

RUN wineboot -u
RUN wineserver -w

# Copy nvidia libraries for wine
#COPY --chown=1000:1000 nvidia/nvidia-libs-v1.0.2/ /home/ubuntu/nvidia
#RUN sudo chmod +x /home/ubuntu/nvidia/setup_nvlibs.sh
#RUN /home/ubuntu/nvidia/setup_nvlibs.sh install

# Copy MangoHud config
RUN mkdir -p /home/ubuntu/.config/MangoHud

COPY --chown=1000:1000 \
    mangohud/MangoHud.conf \
    /home/ubuntu/.config/MangoHud/MangoHud.conf

RUN chown -R 1000:1000 /home/ubuntu/

# Selkies Tweaks
#COPY selkies-tweaks/python/__main__.py /usr/local/lib/python3.12/dist-packages/selkies_gstreamer/__main__.py
#COPY selkies-tweaks/python/signalling_web.py /usr/local/lib/python3.12/dist-packages/selkies_gstreamer/signalling_web.py
#COPY selkies-tweaks/web/app.js /opt/gst-web/app.js
#COPY --chown=1000:1000 selkies-tweaks/entrypoint.sh /etc/entrypoint.sh
#RUN chmod -f 755 /etc/entrypoint.sh

# Entrypoint
#COPY --chown=1000:1000 entrypoint.sh /entrypoint.sh
#COPY --chown=1000:1000 run_app.sh /run_app.sh
COPY --chown=1000:1000 create_wineprefix.sh /home/ubuntu/create_wineprefix.sh
RUN printf '[Desktop Entry]\nType=Application\nName=Create wineprefix\nExec=sh -c "sh /home/ubuntu/create_wineprefix.sh > /tmp/wineprefix.log 2>&1"\nTerminal=false\n' \
    | sudo tee /etc/xdg/autostart/create-wineprefix.desktop > /dev/null
#RUN sudo chmod +x /entrypoint.sh
#RUN sudo chmod +x /run_app.sh
#ENTRYPOINT ["/entrypoint.sh"]

# Sensible defaults
ENV NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    DISPLAY=:1

