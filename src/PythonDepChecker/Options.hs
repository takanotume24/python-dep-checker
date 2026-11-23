module PythonDepChecker.Options (Options (..)) where

data Options = Options
  { optionsEntrypoint :: FilePath
  , optionsRoots :: [FilePath]
  , optionsAbsolute :: Bool
  }
  deriving (Eq, Show)
