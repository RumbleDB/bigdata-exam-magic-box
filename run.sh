#!/bin/sh
# Reset this lab only: remove its containers and database volume, fetch the
# latest Jupyter image, and start again. Other Docker projects are untouched.
set -e
cd "$(dirname "$0")"
docker compose down -v --remove-orphans
docker compose pull
docker compose up -d
echo "Jupyter: http://localhost:8888  |  Adminer: http://localhost:8080"
