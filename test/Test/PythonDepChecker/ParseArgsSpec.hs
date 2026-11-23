module Test.PythonDepChecker.ParseArgsSpec (spec) where

import PythonDepChecker.Options (Options (..))
import PythonDepChecker.ParseArgs (parseArgs)
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "parseArgs" $ do
  it "accepts a Python file as the entrypoint" $
    parseArgs ["script.py"]
      `shouldBe` Right (Just (Options "script.py" ["."] False))

  it "defaults the root to the entrypoint's directory" $
    parseArgs ["examples/script.py"]
      `shouldBe` Right (Just (Options "examples/script.py" ["examples"] False))

  it "accepts a notebook as the entrypoint" $
    parseArgs ["notebook.ipynb", "--absolute"]
      `shouldBe` Right (Just (Options "notebook.ipynb" ["."] True))

  it "collects repeatable roots in command-line order" $
    parseArgs ["script.py", "--root", "src", "--root", "lib"]
      `shouldBe` Right (Just (Options "script.py" ["src", "lib"] False))

  it "accepts --root=DIR" $
    parseArgs ["--root=src", "script.py"]
      `shouldBe` Right (Just (Options "script.py" ["src"] False))

  it "rejects a missing entrypoint" $
    parseArgs [] `shouldBe` Left "missing entrypoint path"

  it "rejects more than one entrypoint" $
    parseArgs ["a.py", "b.py"]
      `shouldBe` Left "expected exactly one entrypoint path"

  it "rejects --root without a value" $
    parseArgs ["--root"]
      `shouldBe` Left "--root requires a directory"

  it "rejects unknown options" $
    parseArgs ["--unknown"]
      `shouldBe` Left "unknown option: --unknown"

  it "returns Nothing for --help" $
    parseArgs ["--help"] `shouldBe` Right Nothing
