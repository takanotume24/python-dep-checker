module PythonDepChecker.ReadEntrySources (readEntrySources) where

import Data.Char (toLower)
import Data.Text (Text)
import PythonDepChecker.ReadNotebookSources (readNotebookSources)
import PythonDepChecker.ReadPythonFile (readPythonFile)
import System.FilePath (takeExtension)

readEntrySources :: FilePath -> IO (Either String [Text])
readEntrySources path =
  case map toLower (takeExtension path) of
    ".ipynb" -> readNotebookSources path
    ".py" -> singleSource <$> readPythonFile path
    ".pyi" -> singleSource <$> readPythonFile path
    extension ->
      pure
        ( Left
            ( path
                ++ ": unsupported entrypoint type '"
                ++ extension
                ++ "' (expected .ipynb, .py, or .pyi)"
            )
        )
  where
    singleSource = fmap (: [])
