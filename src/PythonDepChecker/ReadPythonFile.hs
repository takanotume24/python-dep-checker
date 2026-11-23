{-# LANGUAGE OverloadedStrings #-}

module PythonDepChecker.ReadPythonFile (readPythonFile) where

import Control.Exception (IOException, try)
import qualified Data.ByteString as BS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Text.Encoding.Error (lenientDecode)

readPythonFile :: FilePath -> IO (Either String Text)
readPythonFile path = do
  result <- try (BS.readFile path) :: IO (Either IOException BS.ByteString)
  pure $ case result of
    Left err -> Left (path ++ ": " ++ show err)
    Right bytes ->
      Right (normaliseNewlines (TE.decodeUtf8With lenientDecode (stripUtf8Bom bytes)))
  where
    stripUtf8Bom bytes
      | BS.take 3 bytes == BS.pack [0xEF, 0xBB, 0xBF] = BS.drop 3 bytes
      | otherwise = bytes

    normaliseNewlines = T.replace "\r" "\n" . T.replace "\r\n" "\n"
