# examples

`python-dep-checker` の動作確認用ファイルです。

```
examples/
├── notebook.ipynb          # .ipynb 起点のサンプル
├── script.py               # .py 起点のサンプル
└── demo_pkg/
    ├── __init__.py
    ├── core.py             # 相対 import と絶対 import
    ├── sibling.py
    └── utils/
        ├── __init__.py
        └── helpers.py
```

## 実行例

notebook を起点にする場合:

```bash
cabal run python-dep-checker -- examples/notebook.ipynb
```

Python ファイルを起点にする場合:

```bash
cabal run python-dep-checker -- examples/script.py
```

どちらも次の 5 ファイルが出力されます（順序はパス順）。

```
examples/demo_pkg/__init__.py
examples/demo_pkg/core.py
examples/demo_pkg/sibling.py
examples/demo_pkg/utils/__init__.py
examples/demo_pkg/utils/helpers.py
```

`examples/script.py` を `--root examples` 付きで実行しても同じ結果です。
