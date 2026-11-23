module PythonDepChecker.ParseArgs (parseArgs) where

import Data.List (isPrefixOf, stripPrefix)
import PythonDepChecker.Options (Options (..))
import System.FilePath (normalise, takeDirectory)

parseArgs :: [String] -> Either String (Maybe Options)
parseArgs = go [] False []
  where
    go roots useAbsolute notebooks [] =
      case reverse notebooks of
        [notebook] ->
          Right
            ( Just
                Options
                  { optionsNotebook = notebook
                  , optionsRoots =
                      map normalise
                        (if null roots then [takeDirectory notebook] else reverse roots)
                  , optionsAbsolute = useAbsolute
                  }
            )
        [] -> Left "missing notebook path"
        _ -> Left "expected exactly one notebook path"
    go _ _ _ ("--help" : _) = Right Nothing
    go _ _ _ ("-h" : _) = Right Nothing
    go roots _ notebooks ("--absolute" : rest) =
      go roots True notebooks rest
    go roots useAbsolute notebooks ("--root" : directory : rest) =
      go (directory : roots) useAbsolute notebooks rest
    go roots useAbsolute notebooks (argument : rest)
      | Just directory <- stripPrefix "--root=" argument =
          go (directory : roots) useAbsolute notebooks rest
      | "-" `isPrefixOf` argument =
          Left ("unknown option: " ++ argument)
      | otherwise =
          go roots useAbsolute (argument : notebooks) rest
