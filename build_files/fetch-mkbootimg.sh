#!/usr/bin/env bash
# Install AOSP mkbootimg at a pinned commit into <destdir>, sha256-verified.
# Vendored under build_files/vendor/mkbootimg (commit d2bb0af) to avoid CI
# flakes when android.googlesource.com returns 503.
set -euo pipefail

SHA_MKBOOTIMG=37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c
SHA_GKICERT=1bb1feec68a13da18d581aa2c631798f86f6bc10b55d587b2dd31446a0f8a203

dest="${1:?usage: fetch-mkbootimg.sh <destdir>}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vendor="${script_dir}/vendor/mkbootimg"

mkdir -p "${dest}/gki"
cp "${vendor}/mkbootimg.py" "${dest}/mkbootimg.py"
cp "${vendor}/gki/generate_gki_certificate.py" "${dest}/gki/generate_gki_certificate.py"
echo "${SHA_MKBOOTIMG}  ${dest}/mkbootimg.py" | sha256sum -c -
echo "${SHA_GKICERT}  ${dest}/gki/generate_gki_certificate.py" | sha256sum -c -
