module PythonDepChecker.StripPythonComments (stripPythonComments) where

import Data.Text (Text)
import qualified Data.Text as T

stripPythonComments :: Text -> Text
stripPythonComments =
  T.intercalate "\n" . map stripLine . T.splitOn "\n"
  where
    stripLine = T.takeWhile (/= '#')
