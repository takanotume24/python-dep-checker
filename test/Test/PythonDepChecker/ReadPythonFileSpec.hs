{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.ReadPythonFileSpec (spec) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import qualified Data.Text as T
import PythonDepChecker.ReadPythonFile (readPythonFile)
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec (Spec, describe, expectationFailure, it, shouldBe)

spec :: Spec
spec = describe "readPythonFile" $ do
  it "normalises CRLF and CR line endings" $
    withSystemTempDirectory "read-python" $ \directory -> do
      let path = directory </> "script.py"
      BSC.writeFile path "import a\r\nimport b\rimport c\n"
      result <- readPythonFile path
      result `shouldBe` Right "import a\nimport b\nimport c\n"

  it "strips a UTF-8 BOM" $
    withSystemTempDirectory "read-python" $ \directory -> do
      let path = directory </> "script.py"
      BS.writeFile path (BS.pack [0xEF, 0xBB, 0xBF] <> BSC.pack "import a\n")
      result <- readPythonFile path
      result `shouldBe` Right "import a\n"

  it "decodes invalid UTF-8 without throwing" $
    withSystemTempDirectory "read-python" $ \directory -> do
      let path = directory </> "script.py"
      BS.writeFile path (BSC.pack "import a\n" <> BS.pack [0xFF])
      result <- readPythonFile path
      case result of
        Left err -> expectationFailure err
        Right text -> T.isPrefixOf "import a" text `shouldBe` True

  it "reports a missing file" $
    withSystemTempDirectory "read-python" $ \directory -> do
      result <- readPythonFile (directory </> "missing.py")
      case result of
        Left _ -> pure ()
        Right text -> expectationFailure ("expected an error, got " ++ show text)
