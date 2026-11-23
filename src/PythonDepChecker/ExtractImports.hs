module PythonDepChecker.ExtractImports (extractImports) where

import Data.Text (Text)
import PythonDepChecker.ImportRef (ImportRef)
import PythonDepChecker.LogicalLines (logicalLines)
import PythonDepChecker.ParseImportLine (parseImportLine)
import PythonDepChecker.StripPythonComments (stripPythonComments)
import PythonDepChecker.StripPythonStrings (stripPythonStrings)

extractImports :: Text -> [ImportRef]
extractImports =
  concatMap parseImportLine
    . logicalLines
    . stripPythonComments
    . stripPythonStrings
