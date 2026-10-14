#!/bin/bash
# Mounted volumes arrive root-owned; the session runs as ubuntu, so fix ownership via sudo before handing over.
sudo chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true &
exec /etc/container-entrypoint.sh "$@"
