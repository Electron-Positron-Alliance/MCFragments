#!/bin/bash
# fetch.sh NAME...: download each source listed in sources.txt into $MCF_PREFIX/src (an existing file is reused)
# and stop unless its sha256 matches.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p "$MCF_PREFIX/src"
for name in "$@"; do
  line=$(awk -v n="$name" '$1 == n {print $2, $3}' "$HERE/sources.txt")
  [ -n "$line" ] || { echo "fetch.sh: $name is not in sources.txt" >&2; exit 1; }
  read -r sha url <<< "$line"
  f="$MCF_PREFIX/src/$name"
  if [ ! -f "$f" ]; then
    curl -fL --retry 3 -o "$f.part" "$url"
    mv "$f.part" "$f"
  fi
  echo "$sha  $f" | sha256sum -c --quiet - || { echo "fetch.sh: sha256 mismatch for $f" >&2; exit 1; }
  echo "fetch.sh: $name OK"
done
