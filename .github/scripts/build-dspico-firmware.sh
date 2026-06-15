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

install_required_file() {
  local source="$1"
  local destination="$2"
  local label="$3"

  if [ ! -s "$source" ]; then
    fail "Missing ${label}: ${source}."
  fi

  cp "$source" "$destination" || fail "Could not install ${label}."
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

is_true() {
  local value

  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    1 | true | yes | on)
      return 0
      ;;
    0 | false | no | off | "")
      return 1
      ;;
    *)
      fail "Invalid boolean value: $1"
      ;;
  esac
}

enable_wrfuxxed_macro() {
  local cmake_lists="$1"

  if grep -Eq '^[[:space:]]*DSPICO_ENABLE_WRFUXXED([[:space:]]|#|$)' "$cmake_lists"; then
    return
  fi

  if grep -Eq '^[[:space:]]*#[[:space:]]*DSPICO_ENABLE_WRFUXXED([[:space:]]|#|$)' "$cmake_lists"; then
    perl -i -pe 's/^([ \t]*)#[ \t]*(DSPICO_ENABLE_WRFUXXED(?=[ \t#]|$))/$1$2/' "$cmake_lists"
    return
  fi

  fail "Could not find DSPICO_ENABLE_WRFUXXED in ${cmake_lists}."
}

export PATH="/opt/wonderful/bin:${PATH}"
if [ -f /opt/wonderful/bin/wf-env ]; then
  set +u
  # shellcheck disable=SC1091
  source /opt/wonderful/bin/wf-env
  set -u
fi

: "${FIRMWARE_REF:=develop}"
: "${BOOTLOADER_REF:=develop}"
: "${DLDI_REF:=develop}"
: "${ENCRYPTOR_REF:=develop}"
: "${ENABLE_DSIDEV:=false}"
: "${ENABLE_WRFUXXED:=false}"
: "${WRFUXXED_REF:=develop}"

WORKFLOW_DIR="${GITHUB_WORKSPACE:-$PWD}"
INPUT_DIR="${INPUT_DIR:-${WORKFLOW_DIR}/files}"
BUILD_ROOT="${BUILD_ROOT:-${RUNNER_TEMP:-$PWD}/dspico-build}"
DLDI_DIR="${BUILD_ROOT}/dspico-dldi"
BOOTLOADER_DIR="${BUILD_ROOT}/dspico-bootloader"
ENCRYPTOR_SRC_DIR="${BUILD_ROOT}/DSRomEncryptor"
FIRMWARE_DIR="${BUILD_ROOT}/dspico-firmware"
WRFUXXED_DIR="${BUILD_ROOT}/dspico-wrfuxxed"
WRFU_TESTER_SHA1="2D65FB7A0C62A4F08954B98C95F42B804FCCFD26"
TWL_DEV_BLOWFISH_SHA1="CFF62F24444F5494001F019D505F9C51D40FC8B3"
NTR_BLOWFISH_FILE="${NTR_BLOWFISH_FILE:-${INPUT_DIR}/ntrBlowfish.bin}"
TWL_BLOWFISH_FILE="${TWL_BLOWFISH_FILE:-${INPUT_DIR}/twlBlowfish.bin}"
TWL_DEV_BLOWFISH_FILE="${TWL_DEV_BLOWFISH_FILE:-${INPUT_DIR}/twlDevBlowfish.bin}"
WRFU_TESTER_FILE="${WRFU_TESTER_FILE:-${INPUT_DIR}/WRFUTester_v0.60_20080821.srl}"

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
if is_true "$ENABLE_WRFUXXED"; then
  clone_repo "https://github.com/LNH-team/dspico-wrfuxxed.git" "$WRFUXXED_REF" "$WRFUXXED_DIR"
fi
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
install_required_file "$NTR_BLOWFISH_FILE" "${ENCRYPTOR_BIN_DIR}/ntrBlowfish.bin" "ntrBlowfish.bin"
assert_sha1 "${ENCRYPTOR_BIN_DIR}/ntrBlowfish.bin" "84E467F2485078E401A17A5F231E3FE6E9686648" "ntrBlowfish.bin"
if is_true "$ENABLE_DSIDEV"; then
  install_required_file "$TWL_DEV_BLOWFISH_FILE" "${ENCRYPTOR_BIN_DIR}/twlDevBlowfish.bin" "twlDevBlowfish.bin"
  assert_sha1 "${ENCRYPTOR_BIN_DIR}/twlDevBlowfish.bin" "$TWL_DEV_BLOWFISH_SHA1" "twlDevBlowfish.bin"
else
  install_required_file "$TWL_BLOWFISH_FILE" "${ENCRYPTOR_BIN_DIR}/twlBlowfish.bin" "twlBlowfish.bin"
  assert_sha1 "${ENCRYPTOR_BIN_DIR}/twlBlowfish.bin" "2DEA11191F28C6CC1956DADB8941AFFD4B2B5102" "twlBlowfish.bin"
fi
echo "::endgroup::"

echo "::group::Create firmware ROM"
mkdir -p "${FIRMWARE_DIR}/roms"
encryptor_args=()
if is_true "$ENABLE_DSIDEV"; then
  encryptor_args+=(--dsidev)
fi
dotnet "$ENCRYPTOR_DLL" "${encryptor_args[@]}" "$BOOTLOADER_NDS" "${FIRMWARE_DIR}/roms/default.nds"
if [ ! -s "${FIRMWARE_DIR}/roms/default.nds" ]; then
  fail "default.nds was not produced."
fi
echo "::endgroup::"

if is_true "$ENABLE_WRFUXXED"; then
  echo "::group::Build and install Wrfuxxed"
  make -C "$WRFUXXED_DIR"
  WRFUXXED_PAYLOAD="$(find "$WRFUXXED_DIR" -type f -name 'uartBufv060.bin' -print -quit)"
  if [ -z "$WRFUXXED_PAYLOAD" ]; then
    fail "uartBufv060.bin was not produced."
  fi
  "$DLDITOOL" "$DLDI_FILE" "$WRFUXXED_PAYLOAD"

  mkdir -p "${FIRMWARE_DIR}/data" "${FIRMWARE_DIR}/roms"
  cp "$WRFUXXED_PAYLOAD" "${FIRMWARE_DIR}/data/uartBufv060.bin"
  install_required_file "$WRFU_TESTER_FILE" "${FIRMWARE_DIR}/roms/dsimode.nds" "WRFU Tester v0.60 ROM"
  assert_sha1 "${FIRMWARE_DIR}/roms/dsimode.nds" "$WRFU_TESTER_SHA1" "WRFU Tester v0.60 ROM"
  enable_wrfuxxed_macro "${FIRMWARE_DIR}/CMakeLists.txt"
  echo "::endgroup::"
fi

echo "::group::Build firmware"
ln -s "${FIRMWARE_DIR}/pico-sdk" "${BUILD_ROOT}/pico-sdk"
bash "${FIRMWARE_DIR}/compile.sh"
if [ ! -s "${FIRMWARE_DIR}/build/DSpico.uf2" ]; then
  fail "DSpico.uf2 was not produced."
fi
cp "${FIRMWARE_DIR}/build/DSpico.uf2" "${GITHUB_WORKSPACE:-$PWD}/DSpico.uf2"
echo "::endgroup::"

echo "DSpico.uf2 is ready."
