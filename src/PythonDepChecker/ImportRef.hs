module PythonDepChecker.ImportRef (ImportRef (..)) where

import Data.Text (Text)

data ImportRef = ImportRef
  { importLevel :: Int
  , importModule :: [Text]
  , importNames :: [Text]
  }
  deriving (Eq, Show)
