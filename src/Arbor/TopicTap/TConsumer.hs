module Arbor.TopicTap.TConsumer
( TConsumer
)
where

import Data.ByteString (ByteString)
import Data.IORef      (IORef)
import Kafka.Consumer  (ConsumerRecord, KafkaConsumer, TopicPartition)

data TConsumer m = TConsumer (IORef (TC m)) KafkaConsumer

data TC m = TC
  { pollMessage      :: m (ConsumerRecord (Maybe ByteString) (Maybe ByteString))
  , close            :: m ()
  , commitOffsets    :: [TopicPartition] -> m ()
  , commitAllOffsets :: m ()
  }
