{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.LogicalLinesSpec (spec) where

import PythonDepChecker.LogicalLines (logicalLines)
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "logicalLines" $ do
  it "returns one logical line per physical line by default" $
    logicalLines "import a\nimport b\n"
      `shouldBe` ["import a", "import b"]

  it "joins backslash continuations" $
    logicalLines "from pkg import \\\n    a\n"
      `shouldBe` ["from pkg import \n    a"]

  it "joins bracketed continuations" $
    logicalLines "from pkg import (\n    a,\n    b,\n)\n"
      `shouldBe` ["from pkg import (\n    a,\n    b,\n)"]

  it "stops joining when the brackets are closed" $
    logicalLines "from pkg import (\n    a,\n)\nimport b\n"
      `shouldBe` ["from pkg import (\n    a,\n)", "import b"]
