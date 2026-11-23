module Test.PythonDepChecker.ResolveImportSpec (spec) where

import Data.List (sort)
import PythonDepChecker.ImportRef (ImportRef (..))
import PythonDepChecker.ResolveImport (resolveImport)
import System.Directory (createDirectoryIfMissing)
import System.FilePath ((</>), takeDirectory)
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "resolveImport" $ do
  it "resolves an absolute package module including package __init__ files" $
    withSystemTempDirectory "resolve" $ \directory -> do
      createFile (directory </> "pkg" </> "__init__.py")
      createFile (directory </> "pkg" </> "mod.py")
      result <-
        resolveImport [directory] (directory </> "notebook.ipynb") (ImportRef 0 ["pkg", "mod"] [])
      sort result
        `shouldBe` sort
          [ directory </> "pkg" </> "__init__.py"
          , directory </> "pkg" </> "mod.py"
          ]

  it "resolves a module imported by name from a package" $
    withSystemTempDirectory "resolve" $ \directory -> do
      createFile (directory </> "pkg" </> "__init__.py")
      createFile (directory </> "pkg" </> "mod.py")
      result <-
        resolveImport [directory] (directory </> "notebook.ipynb") (ImportRef 0 ["pkg"] ["mod"])
      sort result
        `shouldBe` sort
          [ directory </> "pkg" </> "__init__.py"
          , directory </> "pkg" </> "mod.py"
          ]

  it "resolves relative imports against the importer location" $
    withSystemTempDirectory "resolve" $ \directory -> do
      createFile (directory </> "pkg" </> "__init__.py")
      createFile (directory </> "pkg" </> "solo.py")
      createFile (directory </> "pkg" </> "sub" </> "__init__.py")
      createFile (directory </> "pkg" </> "sub" </> "sibling.py")
      let importer = directory </> "pkg" </> "sub" </> "leaf.py"
      sibling <- resolveImport [directory] importer (ImportRef 1 [] ["sibling"])
      parent <- resolveImport [directory] importer (ImportRef 2 [] ["solo"])
      sibling `shouldBe` [directory </> "pkg" </> "sub" </> "sibling.py"]
      parent `shouldBe` [directory </> "pkg" </> "solo.py"]

  it "ignores modules that do not exist under the roots" $
    withSystemTempDirectory "resolve" $ \directory -> do
      result <-
        resolveImport [directory] (directory </> "notebook.ipynb") (ImportRef 0 ["os"] [])
      result `shouldBe` []
  where
    createFile path = do
      createDirectoryIfMissing True (takeDirectory path)
      writeFile path ""
