module PythonDepChecker.Options (Options (..)) where

data Options = Options
  { optionsNotebook :: FilePath
  , optionsRoots :: [FilePath]
  , optionsAbsolute :: Bool
  }
  deriving (Eq, Show)
