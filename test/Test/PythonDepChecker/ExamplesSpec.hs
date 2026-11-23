module Test.PythonDepChecker.ExamplesSpec (spec) where

import Control.Monad (filterM)
import Data.List (sort)
import PythonDepChecker.CollectDependencies (collectDependencies)
import System.Directory (doesDirectoryExist, getCurrentDirectory)
import System.FilePath ((</>), makeRelative, normalise, takeDirectory)
import Test.Hspec (Spec, describe, expectationFailure, it, shouldBe)

spec :: Spec
spec = describe "examples" $ do
  it "analyses the Python entrypoint example" $ do
    examples <- findExamplesDirectory
    result <- collectDependencies [examples] (examples </> "script.py")
    expectFiles examples result

  it "analyses the notebook example" $ do
    examples <- findExamplesDirectory
    result <- collectDependencies [examples] (examples </> "notebook.ipynb")
    expectFiles examples result

  it "finds the same dependencies from both entrypoints" $ do
    examples <- findExamplesDirectory
    fromScript <- collectDependencies [examples] (examples </> "script.py")
    fromNotebook <- collectDependencies [examples] (examples </> "notebook.ipynb")
    fromScript `shouldBe` fromNotebook
  where
    expected =
      [ "demo_pkg/__init__.py"
      , "demo_pkg/core.py"
      , "demo_pkg/sibling.py"
      , "demo_pkg/utils/__init__.py"
      , "demo_pkg/utils/helpers.py"
      ]

    expectFiles examples result =
      case result of
        Left err -> expectationFailure err
        Right files ->
          sort (map (normalise . makeRelative examples) files) `shouldBe` expected

    findExamplesDirectory = do
      current <- getCurrentDirectory
      let candidates =
            [directory </> "examples" | directory <- take 12 (iterate takeDirectory current)]
      found <- filterM doesDirectoryExist candidates
      case found of
        (directory : _) -> pure directory
        [] -> do
          expectationFailure "examples directory not found"
          pure (current </> "examples")
