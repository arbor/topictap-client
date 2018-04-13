module App.Commands.ConsumeS3
  ( cmdConsumeS3
  ) where

import Options.Applicative

runConsumeS3 :: String -> IO ()
runConsumeS3 = putStrLn

cmdConsumeS3 :: Mod CommandFields (IO ())
cmdConsumeS3 = command "consume-s3" $ flip info idm $ runConsumeS3 <$> argument str idm
