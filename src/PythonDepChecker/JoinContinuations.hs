module PythonDepChecker.JoinContinuations (logicalLines) where

import Data.Text (Text)
import qualified Data.Text as T

logicalLines :: Text -> [Text]
logicalLines source = go "" 0 (T.lines source)
  where
    go current _ [] = [current | not (T.null (T.strip current))]
    go current depth (line : rest) =
      let combined = if T.null current then line else current <> "\n" <> line
          depth' = depth + bracketDelta line
          continued = depth' > 0 || "\\" `T.isSuffixOf` line
       in if continued
            then go (dropContinuation combined) depth' rest
            else combined : go "" 0 rest

    dropContinuation text
      | "\\" `T.isSuffixOf` text = T.dropEnd 1 text
      | otherwise = text

    bracketDelta = T.foldl' step 0

    step n c
      | c `elem` ("([{" :: String) = n + 1
      | c `elem` (")]}" :: String) = n - 1
      | otherwise = n
