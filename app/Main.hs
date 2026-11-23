module Main (main) where

import PythonDepChecker.ParseArgs (parseArgs)
import PythonDepChecker.PrintUsage (printUsage)
import PythonDepChecker.Run (run)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  arguments <- getArgs
  case parseArgs arguments of
    Left err -> do
      hPutStrLn stderr err
      printUsage
      exitFailure
    Right Nothing -> printUsage
    Right (Just options) -> run options
