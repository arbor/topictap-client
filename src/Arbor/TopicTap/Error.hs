module Arbor.TopicTap.Error
where

import Kafka.Consumer (KafkaError)

data TopicTapError
  = KafkaErr KafkaError

maybeAsError :: Maybe e -> Either e ()
maybeAsError = maybe (Right ()) Left
{-# INLINE maybeAsError #-}
