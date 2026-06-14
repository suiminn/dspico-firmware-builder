# DSpico Firmware Builder

[日本語](README.ja.md)

This repository provides a GitHub Actions workflow that builds `DSpico.uf2`.

The workflow uploads the generated firmware as a GitHub Actions artifact. For
personal builds, create a private repository from this template before running
the workflow.

## Quick Start

1. Create a private repository from this template
2. Prepare `ntrBlowfish.bin` and `twlBlowfish.bin`
3. Check that both files have the expected SHA-1 hashes
4. Encode both files as base64
5. Add the base64 strings as GitHub Actions secrets
6. Run `Build DSpico firmware` from the `Actions` tab
7. Download `DSpico.uf2` from the workflow artifact

## Required Files

| Secret | Source file | SHA-1 |
| --- | --- | --- |
| `NTR_BLOWFISH_B64` | `ntrBlowfish.bin` | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `TWL_BLOWFISH_B64` | `twlBlowfish.bin` | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## Extract from BIOS Dumps

If you have `biosnds7.rom` and `biosdsi7.rom`, extract the blowfish tables with
these commands. Run them in Bash on macOS, Linux, WSL, or Git Bash.

```bash
dd if=biosnds7.rom of=ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048)) status=progress

dd if=biosdsi7.rom of=twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048)) status=progress
```

## Check SHA-1

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 ntrBlowfish.bin
Get-FileHash -Algorithm SHA1 twlBlowfish.bin
```

macOS:

```bash
shasum -a 1 ntrBlowfish.bin
shasum -a 1 twlBlowfish.bin
```

Linux:

```bash
sha1sum ntrBlowfish.bin
sha1sum twlBlowfish.bin
```

## Encode as Base64

Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ntrBlowfish.bin"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("twlBlowfish.bin"))
```

macOS:

```bash
base64 -i ntrBlowfish.bin | tr -d '\n'
base64 -i twlBlowfish.bin | tr -d '\n'
```

Linux:

```bash
base64 -w 0 ntrBlowfish.bin
base64 -w 0 twlBlowfish.bin
```

## Add GitHub Actions Secrets

1. Open your private repository on GitHub
2. Open `Settings`
3. Open `Secrets and variables` -> `Actions`
4. Click `New repository secret`
5. Add `NTR_BLOWFISH_B64` with the base64 output for `ntrBlowfish.bin`
6. Add `TWL_BLOWFISH_B64` with the base64 output for `twlBlowfish.bin`

## License

The workflow and scripts in this template repository are licensed under the
0BSD License.

This license does not apply to DSpico firmware, DSpico bootloader, DSpico DLDI,
DSRomEncryptor, generated firmware artifacts, or user-provided BIOS-derived
files. Those remain subject to their respective upstream licenses and rights.
