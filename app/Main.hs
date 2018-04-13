module Main where

import App.Commands
import Arbor.TopicTap
import Control.Monad
import Options.Applicative

main :: IO ()
main = join $ execParser (info opts idm)
