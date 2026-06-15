# DSpico Firmware Builder

[日本語](README.ja.md)

This repository provides a GitHub Actions workflow that builds `DSpico.uf2`.

The workflow uploads the generated firmware as a GitHub Actions artifact.
Create a private repository from this template before running the workflow.

## Quick Start

1. Create a private repository from this template
2. Add `ntrBlowfish.bin` to `files/`, and add `twlBlowfish.bin` for normal builds or `twlDevBlowfish.bin` for TWL dev unit builds
3. Check that the added files have the expected SHA-1 hashes
4. Commit and push the files to your private repository
5. Run `Build DSpico firmware` from the `Actions` tab
6. Download the UF2 file from the workflow artifact

To build firmware with Wrfuxxed support, enable the workflow's `enable_wrfuxxed` option and also add the v0.60 WRFU ROM described below.

To build firmware for TWL dev units, add `twlDevBlowfish.bin` instead of `twlBlowfish.bin` and enable the workflow's `enable_dsidev` option.

## Required Files

| File name | Required when | SHA-1 |
| --- | --- | --- |
| `ntrBlowfish.bin` | All builds | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `twlBlowfish.bin` | `enable_dsidev` is disabled | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## Optional Dev TWL Build

`twlDevBlowfish.bin` replaces `twlBlowfish.bin` and is required only when `enable_dsidev` is enabled.

| File name | Required when | SHA-1 |
| --- | --- | --- |
| `twlDevBlowfish.bin` | `enable_dsidev` is enabled | `CFF62F24444F5494001F019D505F9C51D40FC8B3` |

## Optional Wrfuxxed Build

The workflow can also build Wrfuxxed and include it in the firmware. Add the
v0.60 WRFU ROM to `files/` before enabling `enable_wrfuxxed`.

The normal build artifact contains `DSpico.uf2`. When `enable_wrfuxxed` is enabled, the artifact and extracted UF2 file are named `DSpico-wrfuxxed.uf2`.
When `enable_dsidev` is enabled, they are named `DSpico-dsidev.uf2`, or
`DSpico-dsidev-wrfuxxed.uf2` when both options are enabled.

| File name | Description | SHA-1 |
| --- | --- | --- |
| `WRFUTester_v0.60_20080821.srl` | v0.60 WRFU ROM | `2D65FB7A0C62A4F08954B98C95F42B804FCCFD26` |

## Extract from BIOS Dumps

If you have `biosnds7.rom` and `biosdsi7.rom`, extract the blowfish tables with these commands. Place them in `files/` and run them in Bash on macOS, Linux, WSL, or Git Bash.

```bash
mkdir -p files

dd if=files/biosnds7.rom of=files/ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048)) status=progress

dd if=files/biosdsi7.rom of=files/twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048)) status=progress
```

## Check SHA-1

For all builds, check the NTR blowfish table.

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 files\ntrBlowfish.bin
```

macOS:

```bash
shasum -a 1 files/ntrBlowfish.bin
```

Linux:

```bash
sha1sum files/ntrBlowfish.bin
```

For builds without `enable_dsidev`, also check the retail TWL blowfish table:

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 files\twlBlowfish.bin
```

macOS:

```bash
shasum -a 1 files/twlBlowfish.bin
```

Linux:

```bash
sha1sum files/twlBlowfish.bin
```

For `enable_dsidev` builds, also check the TWL dev blowfish table:

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 files\twlDevBlowfish.bin
```

macOS:

```bash
shasum -a 1 files/twlDevBlowfish.bin
```

Linux:

```bash
sha1sum files/twlDevBlowfish.bin
```

For Wrfuxxed builds, also check the v0.60 WRFU ROM.

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 files\WRFUTester_v0.60_20080821.srl
```

macOS:

```bash
shasum -a 1 files/WRFUTester_v0.60_20080821.srl
```

Linux:

```bash
sha1sum files/WRFUTester_v0.60_20080821.srl
```

## Commit the Files

Commit the input files to the private repository that you created from this
template.

## License

The workflow and scripts in this template repository are licensed under the
0BSD License.

This license does not apply to DSpico firmware, DSpico bootloader, DSpico DLDI, DSRomEncryptor, generated firmware artifacts, or user-provided input files. Those remain subject to their respective upstream licenses and rights.
