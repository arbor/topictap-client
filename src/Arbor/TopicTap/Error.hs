module Arbor.TopicTap.Error
where

import Kafka.Consumer (KafkaError)

data TopicTapError
  = KafkaErr KafkaError -- ^ Any error that is coming from Kafka
  | EndOfBackup         -- ^ File backup is exhausted.
  deriving (Show, Eq)

maybeAsError :: Maybe e -> Either e ()
maybeAsError = maybe (Right ()) Left
{-# INLINE maybeAsError #-}
