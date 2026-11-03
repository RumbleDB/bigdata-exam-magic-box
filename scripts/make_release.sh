#!/bin/sh
# Build the student zip: compose setup, notebooks and db/ (the SQL dumps).
#   scripts/make_release.sh 2027-spring
#   gh release create 2027-spring dist/bigdata-exam-magic-box-2027-spring.zip --title "Exam lab 2027 Spring"
set -eu
cd "$(dirname "$0")/.."

NAME="bigdata-exam-magic-box-${1:?usage: $0 <name, e.g. 2027-spring>}"
OUT="dist/$NAME"
REPO=$(sed -n 's/^REPO=//p' .env)

# A zip with the wrong REPO would pull an image that is never updated
ORIGIN=$(git remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s#\.git$##' | tr '[:upper:]' '[:lower:]')
[ -z "$ORIGIN" ] || [ "$ORIGIN" = "$REPO" ] || { echo "REPO=$REPO in .env, but origin is $ORIGIN" >&2; exit 1; }

rm -rf "$OUT" "$OUT.zip"
trap 'rm -rf "$OUT"' EXIT
mkdir -p "$OUT"
ls db/*.sql >/dev/null || { echo "No SQL dumps in db/" >&2; exit 1; }
cp -R .env docker-compose.yml run.sh README.md notebooks db "$OUT/"

# Relative links work on GitHub, not in the unzipped copy
sed -i.bak "s#](\.\./\.\./#](https://github.com/$REPO/#g" "$OUT/README.md" && rm "$OUT/README.md.bak"

(cd dist && zip -qr "$NAME.zip" "$NAME" -x '*/.DS_Store' '*/.ipynb_checkpoints/*' '*/.virtual_documents/*')
echo "Created $OUT.zip ($(du -h "$OUT.zip" | awk "{print \$1}"))"
