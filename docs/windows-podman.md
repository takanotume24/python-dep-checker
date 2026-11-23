# Windows（Podman のみ）で実行する

このドキュメントでは、Docker Desktop・Nix・GHC をホストへインストールせず、
`podman` コマンドだけで `python-dep-checker` のイメージをビルドして実行する方法を
説明します。

## 前提

- Windows 10/11（x64）
- `podman` コマンドが使えること
  - Podman Desktop でも、Podman CLI だけでも構いません
  - `podman info` が成功する状態（Podman machine が起動済み）にしてください
- Podman 4.1 以降を推奨
  - Windows のドライブパスを `--volume` に直接指定できるようになったのは 4.1 以降です
- 初回ビルド用に、空きディスク 20 GB 以上・メモリ 8 GB 以上を推奨
- 初回ビルド時はインターネット接続が必要です（Nix イメージと Nix キャッシュを取得します）

`podman info` が失敗する場合は、先に Podman machine を起動してください。

```powershell
podman machine start
```

machine 自体がない場合:

```powershell
podman machine init
podman machine start
```

## 追加されるスクリプト

```
scripts/
├── podman-build.ps1  イメージをビルドする
├── podman-build.cmd  上記を cmd.exe から呼ぶためのラッパー
├── podman-run.ps1    コンテナで python-dep-checker を実行する
└── podman-run.cmd    上記を cmd.exe から呼ぶためのラッパー
```

PowerShell の実行ポリシーで `.ps1` がブロックされる場合は、`.cmd` を使うか、
`powershell.exe -ExecutionPolicy Bypass -File ...` で実行してください。
`.cmd` は PowerShell 7（`pwsh`）があればそれを使い、なければ Windows PowerShell 5.1 を
使います。どちらも `-ExecutionPolicy Bypass` を指定しています。

## 1. イメージをビルドする

リポジトリのルートで次を実行します。

```powershell
cd C:\path\to\python-dep-checker
.\scripts\podman-build.cmd
```

PowerShell から直接実行する場合:

```powershell
.\scripts\podman-build.ps1
```

`podman-build.ps1` はスクリプトの親ディレクトリをリポジトリルートとして扱うため、
どのディレクトリから実行しても同じ `Dockerfile` を使ってビルドします。

初回は Nix イメージの取得、Nix キャッシュからの GHC などのダウンロード、
Haskell のコンパイルが走るため、10〜30 分程度かかることがあります。
2 回目以降は Podman のビルドキャッシュが使われます。

ビルド後に動作確認する場合:

```powershell
.\scripts\podman-run.cmd --help
```

キャッシュを使わずに作り直す場合:

```powershell
.\scripts\podman-build.ps1 -NoCache
```

ベースイメージを最新に更新する場合:

```powershell
.\scripts\podman-build.ps1 -Pull
```

イメージ名を変える場合:

```powershell
$env:PDC_IMAGE = "my-python-dep-checker"
.\scripts\podman-build.cmd
```

`PDC_IMAGE` を設定した場合は、実行時にも同じ値を設定してください。

## 2. 実行する

リポジトリのルートで、同梱のサンプルを解析します。

```powershell
.\scripts\podman-run.cmd examples\script.py
.\scripts\podman-run.cmd examples\notebook.ipynb
```

オプションはそのまま `python-dep-checker` に渡されます。

```powershell
# 探索ルートを指定する
.\scripts\podman-run.cmd examples\script.py --root examples

# 複数のルートを指定する
.\scripts\podman-run.cmd examples\notebook.ipynb --root . --root src

# 絶対パスで出力する
.\scripts\podman-run.cmd examples\script.py --absolute

# ヘルプ
.\scripts\podman-run.cmd --help
```

`podman-run.ps1` は次のように動作します。

- カレントディレクトリをコンテナの `/work` にマウントする
- 引数の `\` を `/` に変換する（`examples\script.py` → `examples/script.py`）
- カレントディレクトリ配下の Windows 絶対パスをコンテナ内の相対パスに変換する
- イメージがなければ自動でビルドする

イメージの自動ビルドを無効にする場合:

```powershell
$env:PDC_NO_BUILD = "1"
.\scripts\podman-run.cmd examples\script.py
```

毎回イメージをビルドし直す場合:

```powershell
$env:PDC_ALWAYS_BUILD = "1"
.\scripts\podman-run.cmd examples\script.py
```

### 自分のプロジェクトで使う

いったんこのリポジトリでイメージをビルドしておけば、あとは解析したいプロジェクトの
ルートへ移動してスクリプトを呼ぶだけです。

```powershell
cd C:\work\my-project

# このリポジトリを C:\tools\python-dep-checker に置いている場合
C:\tools\python-dep-checker\scripts\podman-run.cmd src\main.py --root .

C:\tools\python-dep-checker\scripts\podman-run.cmd notebooks\analysis.ipynb --root . --root src
```

カレントディレクトリだけが `/work` にマウントされます。解析対象のファイルや
`--root` は、カレントディレクトリからの相対パスで指定してください。

```powershell
cd C:\work\my-project

# OK: カレントディレクトリ配下
C:\tools\python-dep-checker\scripts\podman-run.cmd examples\script.py

# OK: カレントディレクトリ配下の Windows 絶対パス（自動で相対パスに変換）
C:\tools\python-dep-checker\scripts\podman-run.cmd C:\work\my-project\examples\script.py

# NG: カレントディレクトリの外（コンテナから見えない）
C:\tools\python-dep-checker\scripts\podman-run.cmd D:\other-project\script.py
```

このリポジトリのルートをカレントディレクトリにしている場合は、これまでどおり
`.\scripts\podman-run.cmd` で実行できます。

パスに空白が含まれる場合は引用符で囲んでください。

```powershell
.\scripts\podman-run.cmd "examples\my notebook.ipynb"
```

### 出力パスについて

通常の出力は `/work`（＝カレントディレクトリ）からの相対パスなので、
Windows 上でもそのまま読めます。

`--absolute` を付けた場合は、コンテナ内の絶対パスが出力されます。

```
/work/examples/demo_pkg/__init__.py
```

Windows の絶対パスに変換したい場合は、PowerShell のパイプラインで置換できます。

```powershell
$root = (Get-Location).Path
.\scripts\podman-run.cmd examples\script.py --absolute |
    ForEach-Object { ($_ -replace '^/work', $root) -replace '/', '\' }
```

## 3. スクリプトを使わずに実行する

スクリプトの内部で実行しているコマンドは次のとおりです。

```powershell
# ビルド（リポジトリのルートで）
podman build --tag python-dep-checker --file Dockerfile .

# 実行（解析したいプロジェクトのルートで）
podman run --rm `
    --volume "$((Get-Location).Path):/work" `
    --workdir /work `
    python-dep-checker examples/script.py
```

PowerShell では行末の `` ` `` が継続行です。1 行で書いても構いません。

## 環境変数

| 変数 | 既定値 | 説明 |
| --- | --- | --- |
| `PDC_IMAGE` | `python-dep-checker` | 使用するイメージ名 |
| `PDC_ALWAYS_BUILD` | 未設定 | `1` / `true` / `yes` で実行前に必ずビルドする |
| `PDC_NO_BUILD` | 未設定 | `1` / `true` / `yes` で自動ビルドを禁止する |
| `PDC_MOUNT_SOURCE` | カレントディレクトリ | `/work` にマウントするホスト側パスを上書きする |

## トラブルシューティング

### `podman` が見つからない

新しいターミナルを開き直してください。Podman Desktop をインストールした直後は、
PATH が現在のターミナルに反映されていないことがあります。

```powershell
podman --version
```

### Podman machine に接続できない

```powershell
podman machine list
podman machine start
```

Podman Desktop の Settings → Resources から machine の状態も確認できます。

### ビルドが遅い、またはネットワークエラーになる

初回ビルドは Nix イメージの取得と GHC のダウンロードを含むため時間がかかります。
プロキシ環境では、Podman machine 側にもプロキシ設定が必要になる場合があります。
ビルド中にディスク不足が出る場合は、Podman Desktop の Settings → Resources で
machine のディスクを増やすか、machine を作り直してください。

### `/work` が空に見える、ファイルが見つからない

- Podman 4.1 より前は Windows のドライブパス指定に対応していません。
  アップデートしてください
- カレントディレクトリが、解析対象を含むディレクトリになっているか確認してください
- ネットワークドライブや OneDrive の仮想ファイルは、Podman machine から見えない
  ことがあります。ローカルディスク（例: `C:\work\...`）へコピーして実行してください
- WSL バックエンドでどうしてもマウントできない場合は、`PDC_MOUNT_SOURCE` に
  Podman machine 内から見えるパスを指定できます

  ```powershell
  $env:PDC_MOUNT_SOURCE = "/mnt/c/work/my-project"
  .\scripts\podman-run.cmd src\main.py --root .
  ```

### `--absolute` の出力が `/work/...` になる

コンテナ内のパスとしては正しい動作です。Windows のパスが必要な場合は、
「出力パスについて」の置換例を使ってください。

### コードを変更したのにイメージが更新されない

`podman-run` はイメージが存在する場合、自動では再ビルドしません。

```powershell
.\scripts\podman-build.ps1
```

または次のように実行してください。

```powershell
$env:PDC_ALWAYS_BUILD = "1"
.\scripts\podman-run.cmd examples\script.py
```

### ファイル名の大文字小文字でエラーになる

コンテナ内は Linux なので、パスの大文字小文字を区別します。
Windows 上の実際のファイル名と一致するように指定してください。

## 制限

- ホスト側にコンテナ用の Linux バイナリは生成されません。実行は常にコンテナ内です。
- カレントディレクトリの外にあるファイルは解析できません。
  必要に応じて、それらを含むディレクトリへ移動してから実行してください。
- 初回ビルドにはネットワーク接続と相応のディスク容量が必要です。
