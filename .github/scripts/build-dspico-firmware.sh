#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "::error::$*"
  exit 1
}

clone_repo() {
  local repo_url="$1"
  local ref="$2"
  local destination="$3"

  git clone --depth 1 --branch "$ref" "$repo_url" "$destination"
}

write_base64_secret() {
  local secret_value="$1"
  local destination="$2"
  local secret_name="$3"

  if [ -z "$secret_value" ]; then
    fail "Missing GitHub Secret ${secret_name}. Store the required binary as base64."
  fi

  printf '%s' "$secret_value" | base64 --decode > "$destination" \
    || fail "Could not decode ${secret_name}."
}

assert_sha1() {
  local file="$1"
  local expected="$2"
  local label="$3"
  local actual

  actual="$(sha1sum "$file" | awk '{print toupper($1)}')"
  if [ "$actual" != "$expected" ]; then
    fail "${label} has SHA-1 ${actual}, expected ${expected}."
  fi
}

export PATH="/opt/wonderful/bin:${PATH}"
if [ -f /opt/wonderful/bin/wf-env ]; then
  # shellcheck disable=SC1091
  set +u
  source /opt/wonderful/bin/wf-env
  set -u
fi

: "${FIRMWARE_REF:=develop}"
: "${BOOTLOADER_REF:=develop}"
: "${DLDI_REF:=develop}"
: "${ENCRYPTOR_REF:=develop}"

BUILD_ROOT="${BUILD_ROOT:-${RUNNER_TEMP:-$PWD}/dspico-build}"
DLDI_DIR="${BUILD_ROOT}/dspico-dldi"
BOOTLOADER_DIR="${BUILD_ROOT}/dspico-bootloader"
ENCRYPTOR_SRC_DIR="${BUILD_ROOT}/DSRomEncryptor"
FIRMWARE_DIR="${BUILD_ROOT}/dspico-firmware"

case "$BUILD_ROOT" in
  "" | "/" | "$PWD")
    fail "Refusing to use unsafe BUILD_ROOT: ${BUILD_ROOT}"
    ;;
esac

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"

echo "::group::Clone sources"
clone_repo "https://github.com/LNH-team/dspico-dldi.git" "$DLDI_REF" "$DLDI_DIR"
clone_repo "https://github.com/LNH-team/dspico-bootloader.git" "$BOOTLOADER_REF" "$BOOTLOADER_DIR"
clone_repo "https://github.com/Gericom/DSRomEncryptor.git" "$ENCRYPTOR_REF" "$ENCRYPTOR_SRC_DIR"
clone_repo "https://github.com/LNH-team/dspico-firmware.git" "$FIRMWARE_REF" "$FIRMWARE_DIR"
echo "::endgroup::"

echo "::group::Initialize submodules"
git -C "$BOOTLOADER_DIR" submodule update --init
git -C "$FIRMWARE_DIR" submodule update --init
git -C "${FIRMWARE_DIR}/pico-sdk" submodule update --init
echo "::endgroup::"

DLDITOOL="${DLDITOOL:-/opt/wonderful/thirdparty/blocksds/core/tools/dlditool/dlditool}"
if [ ! -x "$DLDITOOL" ]; then
  DLDITOOL="$(command -v dlditool || true)"
fi
if [ -z "$DLDITOOL" ] || [ ! -x "$DLDITOOL" ]; then
  fail "Could not find dlditool. Check that BlocksDS installed successfully."
fi

echo "::group::Build DSpico DLDI"
make -C "$DLDI_DIR"
DLDI_FILE="$(find "$DLDI_DIR" -type f -name 'DSpico.dldi' -print -quit)"
if [ -z "$DLDI_FILE" ]; then
  fail "DSpico.dldi was not produced."
fi
echo "::endgroup::"

echo "::group::Build and patch bootloader"
make -C "$BOOTLOADER_DIR"
BOOTLOADER_NDS="${BOOTLOADER_DIR}/BOOTLOADER.nds"
if [ ! -s "$BOOTLOADER_NDS" ]; then
  fail "BOOTLOADER.nds was not produced."
fi
"$DLDITOOL" "$DLDI_FILE" "$BOOTLOADER_NDS"
echo "::endgroup::"

echo "::group::Build DSRomEncryptor"
dotnet build "${ENCRYPTOR_SRC_DIR}/DSRomEncryptor.sln" --configuration Release
ENCRYPTOR_BIN_DIR="${ENCRYPTOR_SRC_DIR}/DSRomEncryptor/bin/Release/net9.0"
ENCRYPTOR_DLL="${ENCRYPTOR_BIN_DIR}/DSRomEncryptor.dll"
if [ ! -s "$ENCRYPTOR_DLL" ]; then
  fail "DSRomEncryptor.dll was not produced."
fi
echo "::endgroup::"

echo "::group::Install DSRomEncryptor key sources"
write_base64_secret "${NTR_BLOWFISH_B64:-}" "${ENCRYPTOR_BIN_DIR}/ntrBlowfish.bin" "NTR_BLOWFISH_B64"
write_base64_secret "${TWL_BLOWFISH_B64:-}" "${ENCRYPTOR_BIN_DIR}/twlBlowfish.bin" "TWL_BLOWFISH_B64"
assert_sha1 "${ENCRYPTOR_BIN_DIR}/ntrBlowfish.bin" "84E467F2485078E401A17A5F231E3FE6E9686648" "NTR_BLOWFISH_B64"
assert_sha1 "${ENCRYPTOR_BIN_DIR}/twlBlowfish.bin" "2DEA11191F28C6CC1956DADB8941AFFD4B2B5102" "TWL_BLOWFISH_B64"
echo "::endgroup::"

echo "::group::Create firmware ROM"
mkdir -p "${FIRMWARE_DIR}/roms"
dotnet "$ENCRYPTOR_DLL" "$BOOTLOADER_NDS" "${FIRMWARE_DIR}/roms/default.nds"
if [ ! -s "${FIRMWARE_DIR}/roms/default.nds" ]; then
  fail "default.nds was not produced."
fi
echo "::endgroup::"

echo "::group::Build firmware"
ln -s "${FIRMWARE_DIR}/pico-sdk" "${BUILD_ROOT}/pico-sdk"
bash "${FIRMWARE_DIR}/compile.sh"
if [ ! -s "${FIRMWARE_DIR}/build/DSpico.uf2" ]; then
  fail "DSpico.uf2 was not produced."
fi
cp "${FIRMWARE_DIR}/build/DSpico.uf2" "${GITHUB_WORKSPACE:-$PWD}/DSpico.uf2"
echo "::endgroup::"

echo "DSpico.uf2 is ready."
