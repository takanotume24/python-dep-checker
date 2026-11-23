{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.ReadNotebookSourcesSpec (spec) where

import qualified Data.ByteString.Char8 as BS
import PythonDepChecker.ReadNotebookSources (readNotebookSources)
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "readNotebookSources" $ do
  it "concatenates the source arrays of code cells only" $
    withSystemTempDirectory "notebook" $ \directory -> do
      let path = directory </> "sample.ipynb"
      BS.writeFile
        path
        "{\"cells\":[{\"cell_type\":\"code\",\"source\":[\"import a\\n\",\"import b\\n\"]},{\"cell_type\":\"markdown\",\"source\":[\"import c\\n\"]}]}"
      result <- readNotebookSources path
      result `shouldBe` Right ["import a\nimport b\n"]

  it "accepts a source stored as a plain string" $
    withSystemTempDirectory "notebook" $ \directory -> do
      let path = directory </> "sample.ipynb"
      BS.writeFile
        path
        "{\"cells\":[{\"cell_type\":\"code\",\"source\":\"import a\\n\"}]}"
      result <- readNotebookSources path
      result `shouldBe` Right ["import a\n"]

  it "returns Left for invalid JSON" $
    withSystemTempDirectory "notebook" $ \directory -> do
      let path = directory </> "broken.ipynb"
      BS.writeFile path "{"
      result <- readNotebookSources path
      case result of
        Left _ -> pure ()
        Right sources ->
          fail ("expected a parse error, got " ++ show sources)
