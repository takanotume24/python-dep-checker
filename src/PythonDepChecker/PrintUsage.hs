module PythonDepChecker.PrintUsage (printUsage) where

printUsage :: IO ()
printUsage =
  putStrLn $
    unlines
      [ "Usage: python-dep-checker NOTEBOOK [OPTIONS]"
      , ""
      , "List Python files imported by the code cells of a Jupyter notebook."
      , ""
      , "Options:"
      , "  --root DIR     Search root for absolute imports (repeatable)."
      , "                 Defaults to the notebook's directory."
      , "  --absolute     Print absolute paths instead of paths relative to CWD."
      , "  -h, --help     Show this help."
      ]
