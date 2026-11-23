{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.ReadEntrySourcesSpec (spec) where

import qualified Data.ByteString.Char8 as BS
import PythonDepChecker.ReadEntrySources (readEntrySources)
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec (Spec, describe, expectationFailure, it, shouldBe, shouldContain)

spec :: Spec
spec = describe "readEntrySources" $ do
  it "reads a Python file entrypoint" $
    withSystemTempDirectory "entrypoint" $ \directory -> do
      let path = directory </> "script.py"
      writeFile path "import pkg.mod\n"
      result <- readEntrySources path
      result `shouldBe` Right ["import pkg.mod\n"]

  it "reads a notebook entrypoint" $
    withSystemTempDirectory "entrypoint" $ \directory -> do
      let path = directory </> "notebook.ipynb"
      BS.writeFile
        path
        "{\"cells\":[{\"cell_type\":\"code\",\"source\":[\"import pkg.mod\\n\"]}]}"
      result <- readEntrySources path
      result `shouldBe` Right ["import pkg.mod\n"]

  it "accepts a .pyi entrypoint" $
    withSystemTempDirectory "entrypoint" $ \directory -> do
      let path = directory </> "stub.pyi"
      writeFile path "from pkg.mod import value\n"
      result <- readEntrySources path
      result `shouldBe` Right ["from pkg.mod import value\n"]

  it "rejects an unsupported entrypoint type" $
    withSystemTempDirectory "entrypoint" $ \directory -> do
      let path = directory </> "notes.txt"
      writeFile path "import pkg.mod\n"
      result <- readEntrySources path
      case result of
        Left err -> err `shouldContain` "unsupported entrypoint type"
        Right sources -> expectationFailure ("expected an error, got " ++ show sources)

  it "reports a missing entrypoint" $
    withSystemTempDirectory "entrypoint" $ \directory -> do
      result <- readEntrySources (directory </> "missing.py")
      case result of
        Left _ -> pure ()
        Right sources -> expectationFailure ("expected an error, got " ++ show sources)
