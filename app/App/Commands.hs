module App.Commands where

import App.Commands.ConsumeS3
import App.Commands.ShowBackups
import Data.Monoid
import Options.Applicative

opts :: Parser (IO ())
opts = subparser $ mempty
  <>  cmdConsumeS3
  <>  cmdShowBackups
