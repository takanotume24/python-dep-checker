module PythonDepChecker.ToDisplayPath (toDisplayPath) where

import System.Directory (getCurrentDirectory, makeAbsolute)
import System.FilePath (makeRelative, normalise)

toDisplayPath :: Bool -> FilePath -> IO FilePath
toDisplayPath useAbsolute path
  | useAbsolute = normalise <$> makeAbsolute path
  | otherwise = do
      current <- getCurrentDirectory
      pure (normalise (makeRelative current path))
