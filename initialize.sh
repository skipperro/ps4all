# Build docker image, create cache directrory and set permissions for cache to 777
#!/bin/bash
set -e

# Cleanup cache first
sudo rm -rf .cache
mkdir -p .cache/umu .cache/appdata .cache/nvidia
sudo chown -R 1000:1000 .cache
sudo chmod -R 777 .cache

# Run docker image with cache mounted and run umu-run once to download and cache the runtime
sudo docker compose run --rm --entrypoint /bin/bash egl -c "cd /home/ubuntu && umu-run ''"