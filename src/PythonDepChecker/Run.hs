module PythonDepChecker.Run (run) where

import PythonDepChecker.CollectDependencies (collectDependencies)
import PythonDepChecker.Options (Options (..))
import PythonDepChecker.ToDisplayPath (toDisplayPath)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

run :: Options -> IO ()
run options = do
  result <- collectDependencies (optionsRoots options) (optionsNotebook options)
  case result of
    Left err -> do
      hPutStrLn stderr err
      exitFailure
    Right files -> do
      paths <- mapM (toDisplayPath (optionsAbsolute options)) files
      mapM_ putStrLn paths
