#!/bin/sh
# Build the student zip: compose setup, notebooks and db/ (the SQL dumps).
#   scripts/make_release.sh 2027-spring
#   gh release create 2027-spring dist/bigdata-exam-magic-box-2027-spring.zip --title "Exam lab 2027 Spring"
set -eu
cd "$(dirname "$0")/.."

NAME="bigdata-exam-magic-box-${1:?usage: $0 <name, e.g. 2027-spring>}"
OUT="dist/$NAME"

# The Jupyter image students pull, e.g. ghcr.io/rumbledb/bigdata-exam-magic-box:latest
IMAGE=$(sed -n 's#^ *image: *\(ghcr\.io/.*\)#\1#p' docker-compose.yml)
REPO=$(echo "$IMAGE" | sed 's#^ghcr\.io/##; s#:.*##')

# A zip with the wrong repository would pull an image that is never updated
ORIGIN=$(git remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s#\.git$##' | tr '[:upper:]' '[:lower:]')
[ -z "$ORIGIN" ] || [ "$ORIGIN" = "$REPO" ] || { echo "docker-compose.yml pulls $IMAGE, but origin is $ORIGIN" >&2; exit 1; }
ls db/*.sql >/dev/null 2>&1 || { echo "No SQL dumps in db/" >&2; exit 1; }

rm -rf "$OUT" "$OUT.zip"
trap 'rm -rf "$OUT"' EXIT
mkdir -p "$OUT"
cp -R docker-compose.yml run.sh notebooks db "$OUT/"
# Relative links work on GitHub, not in the unzipped copy
sed "s#](\.\./\.\./#](https://github.com/$REPO/#g" README.md > "$OUT/README.md"

(cd dist && zip -qr "$NAME.zip" "$NAME" -x '*/.DS_Store' '*/.ipynb_checkpoints/*' '*/.virtual_documents/*')
echo "Created $OUT.zip ($(du -h "$OUT.zip" | awk '{print $1}')) with $IMAGE"
