# DSpico Firmware Builder

[English](README.md)

このリポジトリは、GitHub Actions で `DSpico.uf2` をビルドするための workflow を提供します。

workflow は生成した firmware を GitHub Actions artifact としてアップロードします。
この template から private repository を作成して実行してください。

## クイックスタート

1. この template から private repository を作成する
2. `files/ntrBlowfish.bin` と `files/twlBlowfish.bin` を追加する
3. 両方の SHA-1 が期待値と一致することを確認する
4. private repository に commit / push する
5. `Actions` タブから `Build DSpico firmware` を実行する
6. workflow artifact から UF2 file をダウンロードする

Wrfuxxed 対応 firmware をビルドする場合は、workflow の `enable_wrfuxxed`
option を有効にし、下記の v0.60 WRFU ROM も追加してください。

## 必要なファイル

| File | 説明 | SHA-1 |
| --- | --- | --- |
| `files/ntrBlowfish.bin` | NTR blowfish table | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `files/twlBlowfish.bin` | TWL blowfish table | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## Optional Wrfuxxed ビルド

workflow は Wrfuxxed をビルドして firmware に含めることもできます。
`enable_wrfuxxed` を有効にする前に、v0.60 WRFU ROM を `files/` に追加してください。

通常ビルドの artifact には `DSpico.uf2` が含まれます。`enable_wrfuxxed` を
有効にすると、artifact 名と解凍後の UF2 file 名は `DSpico-wrfuxxed.uf2` になります。

| File | 説明 | SHA-1 |
| --- | --- | --- |
| `files/WRFUTester_v0.60_20080821.srl` | v0.60 WRFU ROM | `2D65FB7A0C62A4F08954B98C95F42B804FCCFD26` |

## BIOS dumps から抽出する

`biosnds7.rom` と `biosdsi7.rom` がある場合は、次のコマンドで blowfish tables を
抽出できます。`files/` に配置し、macOS、Linux、WSL、Git Bash などの Bash で実行してください。

```bash
mkdir -p files

dd if=files/biosnds7.rom of=files/ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048)) status=progress

dd if=files/biosdsi7.rom of=files/twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048)) status=progress
```

## SHA-1 確認

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA1 files\ntrBlowfish.bin
Get-FileHash -Algorithm SHA1 files\twlBlowfish.bin
```

macOS:

```bash
shasum -a 1 files/ntrBlowfish.bin
shasum -a 1 files/twlBlowfish.bin
```

Linux:

```bash
sha1sum files/ntrBlowfish.bin
sha1sum files/twlBlowfish.bin
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

このライセンスは、DSpico firmware、DSpico bootloader、DSpico DLDI、
DSRomEncryptor、生成される firmware artifact、利用者が用意する入力ファイルには
適用されません。それぞれの upstream license と権利に従ってください。
