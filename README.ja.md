# DSpico Firmware Builder

[English](README.md)

このリポジトリは、GitHub Actionsを使用してDSpicoのファームウェアをビルドするためのワークフローを提供します。


## クイックスタート

6. workflow artifact から UF2 file をダウンロードする
1. このテンプレートからプライベートリポジトリを作成する
1. `files/` に `ntrBlowfish.bin` を追加する
1. ビルド対象に応じて、次のいずれかを `files/` に追加する
   - 通常ビルド: `twlBlowfish.bin`
   - TWL開発機向けビルド: `twlDevBlowfish.bin`
1. Wrfuxxed対応ビルドを作成する場合は、`WRFUTester_v0.60_20080821.srl` も `files/` に追加する
1. 追加したファイルのSHA-1値が後述の期待値と一致することを確認する
1. ファイルをコミットしてプッシュする
1. リポジトリの `Actions` タブを開く
1. `Build DSpico firmware` ワークフローを選択し、`Run workflow` を開く
1. 必要に応じてワークフローのオプションを設定する
   - TWL開発機向けビルド: `Build firmware with DSRomEncryptor --dsidev` にチェックを入れる
   - Wrfuxxed対応ビルド: `Build firmware with Wrfuxxed support` にチェックを入れる
1. ワークフローを実行する
1. 実行完了後、アーティファクトをダウンロードする

## 必要なファイル

| ファイル名             | 必要な場合               | SHA-1                                      |
| ----------------- | ------------------- | ------------------------------------------ |
| `ntrBlowfish.bin` | すべてのビルド             | `84E467F2485078E401A17A5F231E3FE6E9686648` |
| `twlBlowfish.bin` | 通常ビルド | `2DEA11191F28C6CC1956DADB8941AFFD4B2B5102` |

## オプション: TWL開発機向けビルド

`Build firmware with DSRomEncryptor --dsidev` を有効にすると、`twlBlowfish.bin` の代わりに `twlDevBlowfish.bin` を使用します。

| ファイル名                | 必要な場合               | SHA-1                                      |
| -------------------- | ------------------- | ------------------------------------------ |
| `twlDevBlowfish.bin` | TWL開発機向けビルド | `CFF62F24444F5494001F019D505F9C51D40FC8B3` |

## オプション: Wrfuxxed対応ビルド

`Build firmware with Wrfuxxed support` を有効にすると、Wrfuxxedをビルドしてファームウェアに含めます。このオプションを使用する場合は、`WRFUTester_v0.60_20080821.srl` を `files/` に追加してください。

| ファイル名                           | 説明             | SHA-1                                      |
| ------------------------------- | -------------- | ------------------------------------------ |
| `WRFUTester_v0.60_20080821.srl` | v0.60 WRFU ROM | `2D65FB7A0C62A4F08954B98C95F42B804FCCFD26` |

生成されるUF2ファイル名は、オプションの組み合わせによって異なります。

| TWL開発機向けビルド | Wrfuxxed対応ビルド | UF2ファイル名                     |
| ------------ | -------------- | ---------------------------- |
| 無効           | 無効             | `DSpico.uf2`                 |
| 無効           | 有効             | `DSpico-wrfuxxed.uf2`        |
| 有効           | 無効             | `DSpico-dsidev.uf2`          |
| 有効           | 有効             | `DSpico-dsidev-wrfuxxed.uf2` |

## BIOSダンプからの抽出

`biosnds7.rom` と `biosdsi7.rom` がある場合は、次のコマンドでBlowfishテーブルを抽出できます。各BIOSダンプを `files/` に配置し、macOS、Linux、WSL、Git BashなどのBash環境で実行してください。

```bash
mkdir -p files

dd if=files/biosnds7.rom of=files/ntrBlowfish.bin \
  bs=1 skip=$((0x30)) count=$((0x1048))

dd if=files/biosdsi7.rom of=files/twlBlowfish.bin \
  bs=1 skip=$((0xC6D0)) count=$((0x1048))
```

## SHA-1の確認

### `ntrBlowfish.bin`

すべてのビルドで確認してください。

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

通常ビルドで確認してください。

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

TWL開発機向けビルドで確認してください。

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

Wrfuxxed対応ビルドで確認してください。

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

## ライセンス

このテンプレートリポジトリに含まれるワークフローおよびスクリプトは、0BSD Licenseの下で提供されます。

このライセンスは、DSpicoファームウェア、DSpicoブートローダー、DSpico DLDI、DSRomEncryptor、生成されるファームウェアのアーティファクト、または利用者が用意する入力ファイルには適用されません。これらには、それぞれの上流プロジェクトのライセンスその他の権利条件が適用されます。
