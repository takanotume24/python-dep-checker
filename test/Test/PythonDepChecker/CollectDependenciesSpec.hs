{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.CollectDependenciesSpec (spec) where

import qualified Data.ByteString.Char8 as BS
import Data.List (sort)
import PythonDepChecker.CollectDependencies (collectDependencies)
import System.Directory (createDirectoryIfMissing)
import System.FilePath ((</>), takeDirectory)
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "collectDependencies" $ do
  it "follows imports transitively from a notebook" $
    withSystemTempDirectory "deps" $ \directory -> do
      writeText (directory </> "pkg" </> "__init__.py") ""
      writeText (directory </> "pkg" </> "mod.py") "from pkg.sub import leaf\n"
      writeText (directory </> "pkg" </> "sub" </> "__init__.py") ""
      writeText (directory </> "pkg" </> "sub" </> "leaf.py") "from os import path\n"
      writeText (directory </> "unrelated.py") ""
      let notebook = directory </> "notebook.ipynb"
      BS.writeFile
        notebook
        "{\"cells\":[{\"cell_type\":\"code\",\"source\":[\"import pkg.mod\\n\"]}]}"
      result <- collectDependencies [directory] notebook
      result
        `shouldBe` Right
          ( sort
              [ directory </> "pkg" </> "__init__.py"
              , directory </> "pkg" </> "mod.py"
              , directory </> "pkg" </> "sub" </> "__init__.py"
              , directory </> "pkg" </> "sub" </> "leaf.py"
              ]
          )

  it "follows imports transitively from a Python entrypoint" $
    withSystemTempDirectory "deps" $ \directory -> do
      writeText (directory </> "pkg" </> "__init__.py") ""
      writeText (directory </> "pkg" </> "mod.py") "from pkg.sub import leaf\n"
      writeText (directory </> "pkg" </> "sub" </> "__init__.py") ""
      writeText (directory </> "pkg" </> "sub" </> "leaf.py") "from os import path\n"
      writeText (directory </> "unrelated.py") ""
      let entrypoint = directory </> "script.py"
      writeText entrypoint "import pkg.mod\n"
      result <- collectDependencies [directory] entrypoint
      result
        `shouldBe` Right
          ( sort
              [ directory </> "pkg" </> "__init__.py"
              , directory </> "pkg" </> "mod.py"
              , directory </> "pkg" </> "sub" </> "__init__.py"
              , directory </> "pkg" </> "sub" </> "leaf.py"
              ]
          )

  it "resolves relative imports from a Python entrypoint" $
    withSystemTempDirectory "deps" $ \directory -> do
      writeText (directory </> "pkg" </> "__init__.py") ""
      writeText (directory </> "pkg" </> "sibling.py") ""
      let entrypoint = directory </> "pkg" </> "runner.py"
      writeText entrypoint "from . import sibling\n"
      result <- collectDependencies [directory] entrypoint
      result `shouldBe` Right [directory </> "pkg" </> "sibling.py"]

  it "reports a missing Python entrypoint" $
    withSystemTempDirectory "deps" $ \directory -> do
      result <- collectDependencies [directory] (directory </> "missing.py")
      case result of
        Left _ -> pure ()
        Right files -> fail ("expected an error, got " ++ show files)

  it "reports invalid notebooks" $
    withSystemTempDirectory "deps" $ \directory -> do
      let notebook = directory </> "broken.ipynb"
      BS.writeFile notebook "{"
      result <- collectDependencies [directory] notebook
      case result of
        Left _ -> pure ()
        Right files -> fail ("expected an error, got " ++ show files)
  where
    writeText path content = do
      createDirectoryIfMissing True (takeDirectory path)
      writeFile path content
