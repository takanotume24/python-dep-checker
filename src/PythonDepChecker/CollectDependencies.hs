module PythonDepChecker.CollectDependencies (collectDependencies) where

import Control.Exception (IOException, try)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text.IO as TIO
import PythonDepChecker.ExtractImports (extractImports)
import PythonDepChecker.ReadNotebookSources (readNotebookSources)
import PythonDepChecker.ResolveImport (resolveImport)

collectDependencies :: [FilePath] -> FilePath -> IO (Either String [FilePath])
collectDependencies roots notebook = do
  sources <- readNotebookSources notebook
  case sources of
    Left err -> pure (Left err)
    Right code -> do
      initial <- resolveRefs notebook (concatMap extractImports code)
      seen <- walk Set.empty initial
      pure (Right (Set.toList seen))
  where
    resolveRefs importer refs =
      concat <$> mapM (resolveImport roots importer) refs

    walk seen [] = pure seen
    walk seen (path : rest)
      | Set.member path seen = walk seen rest
      | otherwise = do
          content <- readPythonFile path
          refs <-
            case content of
              Nothing -> pure []
              Just text -> resolveRefs path (extractImports text)
          walk (Set.insert path seen) (rest ++ refs)

    readPythonFile path = do
      result <- try (TIO.readFile path) :: IO (Either IOException Text)
      pure (either (const Nothing) Just result)
