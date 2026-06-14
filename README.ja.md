# DSpico Firmware Builder

[English](README.md)

このリポジトリは、GitHub Actions で `DSpico.uf2` をビルドするための
workflow を提供します。

workflow は生成した firmware を GitHub Actions artifact としてアップロードします。
個人用にビルドする場合は、この template から private repository を作成して実行してください。

## クイックスタート

1. この template から private repository を作成する
2. `ntrBlowfish.bin` と `twlBlowfish.bin` を用意する
3. 両方の SHA-1 が期待値と一致することを確認する
4. 両方のファイルを base64 化する
5. base64 文字列を GitHub Actions secrets に追加する
6. `Actions` タブから `Build DSpico firmware` を実行する
7. workflow artifact から `DSpico.uf2` をダウンロードする

## 必要なファイル

| Secret | 元ファイル | SHA-1 |
| --- | --- | --- |
| `NTR_BLOWFISH_B64` | `ntrBlowfish.bin` | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `TWL_BLOWFISH_B64` | `twlBlowfish.bin` | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## BIOS dumps から抽出する

`biosnds7.rom` と `biosdsi7.rom` がある場合は、次のコマンドで blowfish tables を
抽出できます。macOS、Linux、WSL、Git Bash などの Bash で実行してください。

```bash
dd if=biosnds7.rom of=ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048)) status=progress

dd if=biosdsi7.rom of=twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048)) status=progress
```

## SHA-1 確認

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

## base64 化

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

## GitHub Actions secrets に追加する

1. GitHub で private repository を開く
2. `Settings` を開く
3. `Secrets and variables` -> `Actions` を開く
4. `New repository secret` を押す
5. `NTR_BLOWFISH_B64` を追加し、`ntrBlowfish.bin` の base64 出力を貼り付ける
6. `TWL_BLOWFISH_B64` を追加し、`twlBlowfish.bin` の base64 出力を貼り付ける

## ライセンス

この template repository に含まれる workflow と scripts は 0BSD License です。

このライセンスは、DSpico firmware、DSpico bootloader、DSpico DLDI、
DSRomEncryptor、生成される firmware artifact、利用者が用意する BIOS 由来ファイルには
適用されません。それぞれの upstream license と権利に従ってください。
