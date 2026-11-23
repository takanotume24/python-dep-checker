{-# LANGUAGE OverloadedStrings #-}

module Test.PythonDepChecker.ExtractImportsSpec (spec) where

import PythonDepChecker.ExtractImports (extractImports)
import PythonDepChecker.ImportRef (ImportRef (..))
import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "extractImports" $ do
  it "parses plain and aliased imports" $
    extractImports "import os\nimport a.b as c\nimport x, y\n"
      `shouldBe` [ ImportRef 0 ["os"] []
                 , ImportRef 0 ["a", "b"] []
                 , ImportRef 0 ["x"] []
                 , ImportRef 0 ["y"] []
                 ]

  it "parses from-imports and drops aliases from names" $
    extractImports "from pkg.mod import alpha, beta as gamma\n"
      `shouldBe` [ImportRef 0 ["pkg", "mod"] ["alpha", "beta"]]

  it "parses relative imports" $
    extractImports "from . import sibling\nfrom ..pkg.mod import thing\n"
      `shouldBe` [ ImportRef 1 [] ["sibling"]
                 , ImportRef 2 ["pkg", "mod"] ["thing"]
                 ]

  it "joins parenthesised multi-line imports" $
    extractImports "from pkg import (\n    alpha,\n    beta,\n)\n"
      `shouldBe` [ImportRef 0 ["pkg"] ["alpha", "beta"]]

  it "ignores imports inside comments and string literals" $
    extractImports
      "# import fake\nimport real\n\"\"\"\nimport fake2\n\"\"\"\nvalue = 'import fake3'\n"
      `shouldBe` [ImportRef 0 ["real"] []]

  it "ignores trailing comments" $
    extractImports "import real  # import fake\n"
      `shouldBe` [ImportRef 0 ["real"] []]
