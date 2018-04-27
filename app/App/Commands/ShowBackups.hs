module App.Commands.ShowBackups
  ( cmdShowBackups
  ) where

import Options.Applicative

runShowBackups :: String -> IO ()
runShowBackups = putStrLn

cmdShowBackups :: Mod CommandFields (IO ())
cmdShowBackups = command "show-backups" $ flip info idm $ runShowBackups <$> argument str idm
