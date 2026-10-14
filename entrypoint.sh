#!/bin/bash
# Mounted volumes arrive root-owned; fix ownership before handing over to the base entrypoint.
echo "ps4all-entrypoint: running as $(id)" >&2
if [ "$(id -u)" -eq 0 ]; then
  chown -R ubuntu:ubuntu /home/ubuntu || echo "ps4all-entrypoint: chown failed" >&2
else
  sudo chown -R ubuntu:ubuntu /home/ubuntu || echo "ps4all-entrypoint: sudo chown failed" >&2
fi
exec /etc/container-entrypoint.sh "$@"
