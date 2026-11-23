module PythonDepChecker.ParseArgs (parseArgs) where

import Data.List (isPrefixOf, stripPrefix)
import PythonDepChecker.Options (Options (..))
import System.FilePath (normalise, takeDirectory)

parseArgs :: [String] -> Either String (Maybe Options)
parseArgs = go [] False []
  where
    go roots useAbsolute entrypoints [] =
      case reverse entrypoints of
        [entrypoint] ->
          Right
            ( Just
                Options
                  { optionsEntrypoint = entrypoint
                  , optionsRoots =
                      map normalise
                        (if null roots then [takeDirectory entrypoint] else reverse roots)
                  , optionsAbsolute = useAbsolute
                  }
            )
        [] -> Left "missing entrypoint path"
        _ -> Left "expected exactly one entrypoint path"
    go _ _ _ ("--help" : _) = Right Nothing
    go _ _ _ ("-h" : _) = Right Nothing
    go roots _ entrypoints ("--absolute" : rest) =
      go roots True entrypoints rest
    go roots useAbsolute entrypoints ("--root" : directory : rest) =
      go (directory : roots) useAbsolute entrypoints rest
    go _ _ _ ("--root" : []) =
      Left "--root requires a directory"
    go roots useAbsolute entrypoints (argument : rest)
      | Just directory <- stripPrefix "--root=" argument =
          go (directory : roots) useAbsolute entrypoints rest
      | "-" `isPrefixOf` argument =
          Left ("unknown option: " ++ argument)
      | otherwise =
          go roots useAbsolute (argument : entrypoints) rest
