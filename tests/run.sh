#!/bin/sh
# Smoke-test a Jupyter image: Postgres, Spark, RumbleDB/JSONiq, the JSONiq
# language server, and the cross-origin protection.
#   tests/run.sh <image>
set -eu
IMAGE="${1:?usage: $0 <image>}"
cd "$(dirname "$0")"
export TEST_IMAGE="$IMAGE"

cleanup() { docker compose down -v --remove-orphans >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

echo "::group::Start stack"
docker compose up -d --wait
for _ in $(seq 1 60); do
    curl -fs -o /dev/null http://127.0.0.1:18888/api/status && break
    sleep 1
done
echo "::endgroup::"

failed=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected $2, got $3"; failed=1; fi
}
status() { curl -s -o /dev/null -w '%{http_code}' -X POST "$@"; }

echo "--- Jupyter access"
check "same-origin request allowed"     201 "$(status -H 'Origin: http://localhost:18888' http://localhost:18888/api/kernels)"
check "request without Origin allowed"  201 "$(status http://127.0.0.1:18888/api/kernels)"
check "cross-origin website blocked"    404 "$(status -H 'Origin: https://evil.example' http://localhost:18888/api/kernels)"
check "DNS rebinding blocked"           403 "$(status -H 'Host: evil.example:18888' http://127.0.0.1:18888/api/kernels)"

echo "--- exam-lab-versions"
docker compose exec -T jupyter exam-lab-versions || failed=1

echo "--- JSONiq language server"
docker compose exec -T jupyter python /home/lsp_test.py || failed=1

echo "--- Notebook"
log=$(mktemp)
if docker compose exec -T jupyter jupyter nbconvert --to notebook --execute /home/smoke.ipynb \
    --output-dir /tmp --ExecutePreprocessor.timeout=600 >"$log" 2>&1; then
    echo "ok   notebook ran, all assertions passed"
else
    echo "FAIL notebook:"; grep -vE 'WARN|Stage [0-9]' "$log" | tail -40; failed=1
fi
rm -f "$log"

if [ "$failed" = 0 ]; then echo "PASSED"; else echo "FAILED"; docker compose logs --tail 50; fi
exit "$failed"
