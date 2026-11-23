module PythonDepChecker.StripPythonStrings (stripPythonStrings) where

import Data.List (isPrefixOf)
import Data.Text (Text)
import qualified Data.Text as T

data StringState
  = Normal
  | Single
  | Double
  | TripleSingle
  | TripleDouble

stripPythonStrings :: Text -> Text
stripPythonStrings = T.pack . go Normal . T.unpack
  where
    go :: StringState -> String -> String
    go _ [] = []
    go Normal (c : cs)
      | c == '\'' =
          case cs of
            ('\'' : '\'' : rest) -> "   " ++ go TripleSingle rest
            _ -> ' ' : go Single cs
      | c == '"' =
          case cs of
            ('"' : '"' : rest) -> "   " ++ go TripleDouble rest
            _ -> ' ' : go Double cs
      | otherwise = c : go Normal cs
    go Single (c : cs)
      | c == '\\' = escaped Single cs
      | c == '\'' = ' ' : go Normal cs
      | c == '\n' = '\n' : go Normal cs
      | otherwise = ' ' : go Single cs
    go Double (c : cs)
      | c == '\\' = escaped Double cs
      | c == '"' = ' ' : go Normal cs
      | c == '\n' = '\n' : go Normal cs
      | otherwise = ' ' : go Double cs
    go TripleSingle input
      | "'''" `isPrefixOf` input = "   " ++ go Normal (drop 3 input)
      | otherwise = tripleChar TripleSingle input
    go TripleDouble input
      | "\"\"\"" `isPrefixOf` input = "   " ++ go Normal (drop 3 input)
      | otherwise = tripleChar TripleDouble input

    escaped state (e : rest) =
      (if e == '\n' then '\n' else ' ') : go state rest
    escaped _ [] = []

    tripleChar state (c : cs)
      | c == '\\' = escaped state cs
      | c == '\n' = '\n' : go state cs
      | otherwise = ' ' : go state cs
    tripleChar _ [] = []
