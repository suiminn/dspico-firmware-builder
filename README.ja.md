# DSpico Firmware Builder

[English](README.md)

このリポジトリは、GitHub Actions で `DSpico.uf2` をビルドするための workflow を提供します。

workflow は生成した firmware を GitHub Actions artifact としてアップロードします。
この template から private repository を作成して実行してください。

## クイックスタート

1. この template から private repository を作成する
2. `files/` に `ntrBlowfish.bin` を追加し、通常 build では `twlBlowfish.bin`、TWL dev unit 用 build では `twlDevBlowfish.bin` を追加する
3. 追加したファイルの SHA-1 が期待値と一致することを確認する
4. private repository に commit / push する
5. `Actions` タブから `Build DSpico firmware` を実行する
6. workflow artifact から UF2 file をダウンロードする

Wrfuxxed 対応 firmware をビルドする場合は、workflow の `enable_wrfuxxed` option を有効にし、下記の v0.60 WRFU ROM も追加してください。

TWL dev unit 用の firmware をビルドする場合は、`twlBlowfish.bin` の代わりに `twlDevBlowfish.bin` を追加し、workflow の `enable_dsidev` option を有効にしてください。

## 必要なファイル

| ファイル名 | 必要な場合 | SHA-1 |
| --- | --- | --- |
| `ntrBlowfish.bin` | すべての build | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `twlBlowfish.bin` | `enable_dsidev` が無効 | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## 任意の Dev TWL ビルド

`twlDevBlowfish.bin` は `twlBlowfish.bin` の代わりになり、`enable_dsidev` が有効な場合だけ必須です。

| ファイル名 | 必要な場合 | SHA-1 |
| --- | --- | --- |
| `twlDevBlowfish.bin` | `enable_dsidev` が有効 | `CFF62F24444F5494001F019D505F9C51D40FC8B3` |

## Optional Wrfuxxed ビルド

workflow は Wrfuxxed をビルドして firmware に含めることもできます。
`enable_wrfuxxed` を有効にする前に、v0.60 WRFU ROM を `files/` に追加してください。

通常ビルドの artifact には `DSpico.uf2` が含まれます。`enable_wrfuxxed` を有効にすると、artifact 名と解凍後の UF2 ファイル名は `DSpico-wrfuxxed.uf2` になります。
`enable_dsidev` を有効にすると `DSpico-dsidev.uf2`、両方を有効にすると
`DSpico-dsidev-wrfuxxed.uf2` になります。

| ファイル名 | 説明 | SHA-1 |
| --- | --- | --- |
| `WRFUTester_v0.60_20080821.srl` | v0.60 WRFU ROM | `2D65FB7A0C62A4F08954B98C95F42B804FCCFD26` |

## BIOS dumps から抽出する

`biosnds7.rom` と `biosdsi7.rom` がある場合は、次のコマンドで blowfish tables を抽出できます。`files/` に配置し、macOS、Linux、WSL、Git Bash などの Bash で実行してください。

```bash
mkdir -p files

dd if=files/biosnds7.rom of=files/ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048)) status=progress

dd if=files/biosdsi7.rom of=files/twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048)) status=progress
```

## SHA-1 確認

すべての build で NTR blowfish table を確認してください。

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

`enable_dsidev` を使わない build では、retail TWL blowfish table も確認してください。

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

`enable_dsidev` ビルドの場合は、TWL dev blowfish table も確認してください。

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

Wrfuxxed ビルドの場合は、v0.60 WRFU ROM も確認してください。

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

## ファイルを commit する

この template から作成した private repository に入力ファイルを commit します。

## ライセンス

この template repository に含まれる workflow と scripts は 0BSD License です。

このライセンスは、DSpico firmware、DSpico bootloader、DSpico DLDI、DSRomEncryptor、生成される firmware artifact、利用者が用意する入力ファイルには適用されません。それぞれの upstream license と権利に従ってください。
