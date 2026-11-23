module PythonDepChecker.PrintUsage (printUsage) where

printUsage :: IO ()
printUsage =
  putStrLn $
    unlines
      [ "Usage: python-dep-checker ENTRYPOINT [OPTIONS]"
      , ""
      , "List Python files imported by a Jupyter notebook (.ipynb) or a Python file (.py)."
      , ""
      , "Options:"
      , "  --root DIR     Search root for absolute imports (repeatable)."
      , "                 Defaults to the entrypoint's directory."
      , "  --absolute     Print absolute paths instead of paths relative to CWD."
      , "  -h, --help     Show this help."
      ]
