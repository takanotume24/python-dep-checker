# python-dep-checker

特定の Jupyter notebook（`.ipynb`）または Python ファイル（`.py`）から呼び出されている
Python ファイルを列挙する CLI です。起点ファイルに書かれた
`import` / `from ... import ...` を静的に解析し、ローカルプロジェクト内の `.py` を
推移的にたどります。

Haskell で実装し、開発環境の依存は Nix（flake）で解決します。
ソース構成の検査には
[haskell-structure-lint](https://github.com/takanotume24/haskell-structure-lint)
を使います。

## できること

- 起点として `.ipynb`（`cell_type == "code"` のセル）と `.py` / `.pyi` を受け付ける
- `import a.b`, `import a.b as c`, `from a.b import c`, 相対 import を解釈する
- コメントや文字列リテラルの中の `import` は無視する
- 見つかった Python ファイルをさらに解析して、import を推移的にたどる
- 実際に存在するローカル `.py` だけを出力する（標準ライブラリ・site-packages は無視）
- パッケージの `__init__.py` も依存ファイルとして含める
- 結果は CWD からの相対パスで、ソートして 1 行 1 ファイル出力する

## 開発環境（devcontainer + Nix）

リポジトリには `.devcontainer/devcontainer.json` と `flake.nix` が含まれています。
VS Code の「Reopen in Container」で、Nix が入ったコンテナが起動します。

初回は `postCreateCommand` が以下を実行します（opencode のインストール、ビルドツールの用意、
cabal index の更新のみ）。

```bash
curl -fsSL https://opencode.ai/v2/install | bash
nix develop --command bash -lc 'cabal update'
```

コンパイルはコンテナ起動後に手動で行います。

```bash
cabal build all
```

手動で環境に入る場合:

```bash
nix develop
```

devShell には GHC 9.10.3、cabal-install、HLS、ormolu、hlint が入ります。
`structure-lint` は `cabal.project` の `source-repository-package` として取得し、
`cabal build all` でビルドされます。

opencode のホスト側グローバル設定（`~/.config/opencode`）は、コンテナの
`/home/vscode/.config/opencode` に read-only でマウントされます。

Nix で実行ファイルをビルドする場合:

```bash
nix build
./result/bin/python-dep-checker path/to/notebook.ipynb
```

## 使い方

```bash
# 起点ファイルと同じディレクトリを import の探索ルートにする
cabal run python-dep-checker -- path/to/notebook.ipynb
cabal run python-dep-checker -- path/to/script.py

# プロジェクトルートや src を探索ルートに指定する（複数指定可）
cabal run python-dep-checker -- notebook.ipynb --root . --root src
cabal run python-dep-checker -- script.py --root . --root src

# 絶対パスで出力する
cabal run python-dep-checker -- notebook.ipynb --root . --absolute
```

`examples/` に実際に動くサンプルがあります。

```bash
cabal run python-dep-checker -- examples/notebook.ipynb
cabal run python-dep-checker -- examples/script.py
```

`nix build` 済みなら `./result/bin/python-dep-checker` を直接使えます。

### Docker で実行

Docker イメージは Nix で実行ファイルをビルドし、実行に必要な共有ライブラリだけを
Debian ベースの最終イメージにコピーします。初回ビルドは Nix の依存取得と GHC による
コンパイルが走るため、数分かかることがあります。

```bash
# イメージをビルド
docker build -t python-dep-checker .

# カレントディレクトリを /work にマウントして実行
docker run --rm -v "$PWD:/work" python-dep-checker examples/script.py
docker run --rm -v "$PWD:/work" python-dep-checker examples/notebook.ipynb
```

Makefile 経由なら次の 1 コマンドでビルドと実行ができます。

```bash
make docker-run
make docker-run ARGS="examples/notebook.ipynb"
make docker-run ARGS="examples/script.py --root examples"
```

`--absolute` を付けた場合、出力されるのはコンテナ内のパス（例:
`/work/examples/...`）です。ホスト側の絶対パスが必要な場合は、通常どおり
`cabal run` / `nix build` したバイナリを使ってください。

### オプション

```
Usage: python-dep-checker ENTRYPOINT [OPTIONS]

  --root DIR     絶対 import を探すルート（繰り返し指定可）
                 省略時は起点ファイルのあるディレクトリ
  --absolute      CWD からの相対パスではなく絶対パスを出力
  -h, --help     ヘルプを表示
```

起点ファイルの拡張子は `.ipynb`、`.py`、`.pyi` を受け付けます。それ以外はエラーになります。

### import の解決

`--root` の下を次のように探します。

| import | 解決先の例 |
| --- | --- |
| `import pkg.mod` | `pkg/__init__.py`, `pkg/mod.py`（または `pkg/mod/__init__.py`） |
| `from pkg import mod` | `pkg/__init__.py`, `pkg/mod.py` |
| `from . import sibling` | 読み込み元ファイルと同じパッケージ内の `sibling.py` |
| `from ..pkg.mod import x` | 読み込み元から見た親パッケージの `pkg/mod.py` |

- `src/` レイアウトのプロジェクトでは `--root src` を追加してください。
- 複数のルートに同じモジュールがある場合は、存在するものをすべて列挙します。
- 見つからない import（標準ライブラリ、サードパーティ）は単に無視します。
- `.py` 起点の場合も、起点ファイル自身は出力に含まれません（あくまで依存先のみ）。

## 制限

- 静的な `import` 文だけを対象にします。`%run`、`!python`、`importlib.import_module`、
  `__import__`、動的な `sys.path` 操作は対象外です。
- notebook の実行順や条件分岐は考慮しません。
- Python の import 解決を完全に再現するものではありません。実運用では
  `--root` をプロジェクトに合わせて指定してください。

## テストと lint

```bash
cabal test
make lint   # cabal run structure-lint -- check / positional
make format # ormolu
```

`structure-lint.json` では、このプロジェクト向けに次を有効にしています。

- 1 ファイル 1 トップレベル関数
- 1 ファイル 1 型定義
- ファイル名と宣言名の一致
- モジュール名とパスの一致
- test 配下のファイル名は `Spec` で終わる
- 1 ファイル 200 行まで
- 位置引数が多すぎる定義の検出

## 構成

```
app/Main.hs                          CLI のエントリポイント
src/PythonDepChecker/
  ParseArgs.hs                       引数解析
  ReadEntrySources.hs                起点ファイルの種類を判定して読む
  ReadNotebookSources.hs             .ipynb からコードセルを読む
  ReadPythonFile.hs                  .py / .pyi を BOM・改行コードを正規化して読む
  StripPythonStrings.hs              文字列リテラルを除去
  StripPythonComments.hs             コメントを除去
  LogicalLines.hs                    継続行を 1 つの論理行にまとめる
  ParseImportLine.hs                 import 文の解析
  ExtractImports.hs                  上記を組み合わせる
  ResolveImport.hs                   import 先のファイル解決
  CollectDependencies.hs             推移的な依存関係の収集
  ToDisplayPath.hs                   出力パスの整形
  Run.hs                             CLI の実行
examples/                            実際に動く .ipynb / .py のサンプル
test/                                 hspec テスト
```
