# DSpico Firmware Builder

[日本語](README.ja.md)

This repository provides a GitHub Actions workflow for building DSpico firmware.

The generated firmware is uploaded as a GitHub Actions artifact. Because the required input files and generated artifacts should not be public, create a private repository from this template before running the workflow.

## Quick Start

1. Create a private repository from this template
1. Add `ntrBlowfish.bin` and `twlBlowfish.bin` to `files/`
   - Only add `twlDevBlowfish.bin` to `files/` if you want to build for TWL dev units
1. To create a Wrfuxxed-supported build, also add `WRFUTester_v0.60_20080821.srl` to `files/`
1. Confirm that the SHA-1 values of the added files match the expected values below
1. Commit and push the files
1. Open the repository's `Actions` tab
1. Select the `Build DSpico firmware` workflow, then open `Run workflow`
1. Configure the workflow options as needed
   - TWL dev unit build: check `Build firmware with DSRomEncryptor --dsidev`
   - Wrfuxxed-supported build: check `Build firmware with Wrfuxxed support`
   - By default, upstream repositories are checked out from `develop`, matching the DSpico guide. For reproducible builds, set each upstream ref option to a specific commit SHA.
1. Run the workflow
1. After the run completes, download the artifact

## Upstream Refs

The workflow follows the upstream DSpico guide by using `develop` for each upstream repository by default. Each ref option accepts a branch, tag, or commit SHA.

For reproducible builds, set the DSpico firmware, bootloader, DLDI, DSRomEncryptor, and Wrfuxxed refs to audited commit SHAs. If Wrfuxxed support is disabled, the Wrfuxxed ref is ignored.

## Required Files

| File name | Required when | SHA-1 |
| --- | --- | --- |
| `ntrBlowfish.bin` | All builds | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `twlBlowfish.bin` | Normal build | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## Optional: TWL Dev Unit Build

When `Build firmware with DSRomEncryptor --dsidev` is enabled, `twlDevBlowfish.bin` is used instead of `twlBlowfish.bin`.

| File name | Required when | SHA-1 |
| --- | --- | --- |
| `twlDevBlowfish.bin` | TWL dev unit build | `CFF62F24444F5494001F019D505F9C51D40FC8B3` |

## Optional: Wrfuxxed-Supported Build

When `Build firmware with Wrfuxxed support` is enabled, Wrfuxxed is built and included in the firmware. To use this option, add `WRFUTester_v0.60_20080821.srl` to `files/`.

| File name | Description | SHA-1 |
| --- | --- | --- |
| `WRFUTester_v0.60_20080821.srl` | v0.60 WRFU ROM | `2D65FB7A0C62A4F08954B98C95F42B804FCCFD26` |

The generated UF2 file name depends on the combination of options.

| TWL dev unit build | Wrfuxxed-supported build | UF2 file name |
| --- | --- | --- |
| Disabled | Disabled | `DSpico.uf2` |
| Disabled | Enabled | `DSpico-wrfuxxed.uf2` |
| Enabled | Disabled | `DSpico-dsidev.uf2` |
| Enabled | Enabled | `DSpico-dsidev-wrfuxxed.uf2` |

## Extract from BIOS Dumps

If you have `biosnds7.rom` and `biosdsi7.rom`, you can extract the Blowfish tables with the following commands. Place each BIOS dump in `files/`, then run the commands in a Bash environment such as macOS, Linux, WSL, or Git Bash.

```bash
mkdir -p files

dd if=files/biosnds7.rom of=files/ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048))

dd if=files/biosdsi7.rom of=files/twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048))
```

## Check SHA-1

### `ntrBlowfish.bin`

Check this for all builds.

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

### `twlBlowfish.bin`

Check this for normal builds.

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

### `twlDevBlowfish.bin`

Check this for TWL dev unit builds.

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

### `WRFUTester_v0.60_20080821.srl`

Check this for Wrfuxxed-supported builds.

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

## License

The workflows and scripts included in this template repository are provided under the 0BSD License.

This license does not apply to the DSpico firmware, DSpico bootloader, DSpico DLDI, DSRomEncryptor, generated firmware artifacts, or user-provided input files. These are subject to the licenses and other rights terms of their respective upstream projects.
