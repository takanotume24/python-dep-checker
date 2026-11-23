{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module PythonDepChecker.ReadNotebookSources (readNotebookSources) where

import Control.Exception (IOException, try)
import Data.Aeson (Value (..), eitherDecodeStrict')
import qualified Data.Aeson.KeyMap as KM
import qualified Data.ByteString as BS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Vector as V

readNotebookSources :: FilePath -> IO (Either String [Text])
readNotebookSources path = do
  result <- try (BS.readFile path) :: IO (Either IOException BS.ByteString)
  pure $ case result of
    Left err -> Left (path ++ ": " ++ show err)
    Right bytes ->
      case eitherDecodeStrict' bytes of
        Left err -> Left (path ++ ": invalid notebook JSON: " ++ err)
        Right value -> Right (cellSources value)
  where
    cellSources = \case
      Object object ->
        case KM.lookup "cells" object of
          Just (Array cells) ->
            [sourceText cell | cell <- V.toList cells, isCodeCell cell]
          _ -> []
      _ -> []

    isCodeCell = \case
      Object object ->
        case KM.lookup "cell_type" object of
          Just (String "code") -> True
          _ -> False
      _ -> False

    sourceText = \case
      Object object ->
        case KM.lookup "source" object of
          Just (String source) -> source
          Just (Array parts) ->
            T.concat [part | String part <- V.toList parts]
          _ -> ""
      _ -> ""
