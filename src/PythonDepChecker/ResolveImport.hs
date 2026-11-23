module PythonDepChecker.ResolveImport (resolveImport) where

import Control.Monad (filterM)
import Data.Char (isAlphaNum)
import Data.List (nub)
import qualified Data.Text as T
import PythonDepChecker.ImportRef (ImportRef (..))
import System.Directory (doesFileExist)
import System.FilePath ((</>), normalise, takeDirectory)

resolveImport :: [FilePath] -> FilePath -> ImportRef -> IO [FilePath]
resolveImport roots importer ref = do
  existing <- filterM doesFileExist (nub candidates)
  pure (nub (map normalise existing))
  where
    bases = case importLevel ref of
      0 -> roots
      level -> [relativeBase level]

    segments = map T.unpack (importModule ref)

    candidates =
      concatMap moduleCandidates bases
        ++ concatMap nameCandidates bases

    moduleCandidates base
      | null segments = []
      | otherwise = packageInits base segments ++ moduleTerminals base segments

    nameCandidates base =
      [ path
      | name <- map T.unpack (importNames ref)
      , validName name
      , path <- submoduleCandidates (moduleDirectory base segments) name
      ]

    relativeBase level =
      iterate takeDirectory (takeDirectory importer) !! (level - 1)

    moduleDirectory base names = foldl (</>) base names

    packageInits base names =
      [ moduleDirectory base (take i names) </> "__init__.py"
      | i <- [1 .. length names - 1]
      ]

    moduleTerminals base names =
      [ moduleDirectory base names ++ ".py"
      , moduleDirectory base names </> "__init__.py"
      ]

    submoduleCandidates directory name =
      [ directory </> name ++ ".py"
      , directory </> name </> "__init__.py"
      ]

    validName name =
      not (null name) && all (\c -> isAlphaNum c || c == '_') name
