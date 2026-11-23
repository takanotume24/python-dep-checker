{-# LANGUAGE OverloadedStrings #-}

module PythonDepChecker.ParseImportLine (parseImportLine) where

import Data.Char (isAlphaNum, isSpace)
import Data.Maybe (mapMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import PythonDepChecker.ImportRef (ImportRef (..))

parseImportLine :: Text -> [ImportRef]
parseImportLine raw
  | Just rest <- stripKeyword "import" line = mapMaybe parsePlain (splitNames rest)
  | Just rest <- stripKeyword "from" line = parseFrom rest
  | otherwise = []
  where
    line = T.strip raw

    stripKeyword keyword text =
      case T.stripPrefix keyword text of
        Just rest
          | T.null rest || isSpace (T.head rest) -> Just (T.strip rest)
        _ -> Nothing

    parsePlain spec =
      case T.words spec of
        [] -> Nothing
        (name : _) ->
          let segments = T.splitOn "." name
           in if validModule segments
                then Just (ImportRef 0 segments [])
                else Nothing

    parseFrom rest =
      case T.breakOn " import " rest of
        (modulePart, namesPart)
          | not (T.null namesPart) ->
              let moduleText = T.strip modulePart
                  (level, segments) = splitRelative moduleText
                  names =
                    filter validName
                      (map nameOf (splitNames (T.drop (T.length " import ") namesPart)))
               in [ImportRef level segments names | level > 0 || not (null segments)]
        _ -> []

    splitRelative text =
      let (dots, rest) = T.span (== '.') text
          level = T.length dots
          segments
            | T.null rest = []
            | otherwise = T.splitOn "." rest
       in (level, segments)

    splitNames text =
      let cleaned = T.filter (\c -> c /= '(' && c /= ')') text
       in [T.strip part | part <- T.splitOn "," cleaned, not (T.null (T.strip part))]

    nameOf part =
      case T.words part of
        (name : _) -> name
        [] -> ""

    validModule segments =
      not (null segments) && all validName segments

    validName name =
      not (T.null name)
        && T.all (\c -> isAlphaNum c || c == '_') name
