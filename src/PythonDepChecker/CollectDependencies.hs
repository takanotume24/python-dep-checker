module PythonDepChecker.CollectDependencies (collectDependencies) where

import qualified Data.Set as Set
import PythonDepChecker.ExtractImports (extractImports)
import PythonDepChecker.ReadEntrySources (readEntrySources)
import PythonDepChecker.ReadPythonFile (readPythonFile)
import PythonDepChecker.ResolveImport (resolveImport)

collectDependencies :: [FilePath] -> FilePath -> IO (Either String [FilePath])
collectDependencies roots entrypoint = do
  sources <- readEntrySources entrypoint
  case sources of
    Left err -> pure (Left err)
    Right code -> do
      initial <- resolveRefs entrypoint (concatMap extractImports code)
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
              Left _ -> pure []
              Right text -> resolveRefs path (extractImports text)
          walk (Set.insert path seen) (rest ++ refs)
