module Arbor.TopicTap.TConsumer
( TConsumer
, createConsumer
, closeConsumer
)
where

import Control.Arrow          (left)
import Control.Monad          (mapM)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.ByteString        (ByteString)
import Data.IORef             (IORef, newIORef, readIORef)
import Data.Monoid            ((<>))
import Kafka.Consumer         (ConsumerGroupId, ConsumerRecord, KafkaConsumer, RebalanceEvent, Timeout, TopicName, TopicPartition)

import qualified Kafka.Consumer as K

import Arbor.TopicTap.Error
import Arbor.TopicTap.Kafka
import Arbor.TopicTap.Options

data TConsumer m = TConsumer KafkaConsumer (IORef (TC m))

data TC m = TC
  { pollMessage      :: m (Either TopicTapError (ConsumerRecord (Maybe ByteString) (Maybe ByteString)))
  , close            :: m (Maybe TopicTapError)
  , commitOffsets    :: [TopicPartition] -> m (Maybe TopicTapError)
  , commitAllOffsets :: m (Maybe TopicTapError)
  }

-- | Creates a new TopicTap consumer.
-- The consumer is expected to be closed with 'closeConsumer` function.
createConsumer :: MonadIO m
               => KafkaConfig
               -> TopicName
               -> ConsumerGroupId
               -> (RebalanceEvent -> IO ())
               -> m (Either TopicTapError (TConsumer m))
createConsumer conf topic cgroup onRebalance = do
  kafka <- createKafkaConsumer conf topic cgroup onRebalance
  mapM (mkTConsumer (_kcPollTimeoutMs conf) ) kafka

-- | Closes the TopicTap consumer.
closeConsumer :: MonadIO m => TConsumer m -> m (Maybe TopicTapError)
closeConsumer (TConsumer kafka iotc) = do
  tc <- liftIO $ readIORef iotc
  tcErr <- close tc
  case tcErr of
    Just err -> pure (Just err)
    Nothing  -> closeKafkaConsumer kafka
-------------------------------------------------------------------------------
mkTConsumer :: MonadIO m => Timeout -> KafkaConsumer -> m (TConsumer m)
mkTConsumer timeout consumer =
  liftIO $ TConsumer consumer <$> newIORef (kafkaTC timeout consumer)

kafkaTC :: MonadIO m => Timeout -> KafkaConsumer -> TC m
kafkaTC timeout consumer = TC
  { pollMessage       = left KafkaErr <$> K.pollMessage consumer timeout
  , close             = pure Nothing
  , commitOffsets     = fmap (fmap KafkaErr) . K.commitPartitionsOffsets K.OffsetCommit consumer
  , commitAllOffsets  = fmap KafkaErr <$> K.commitAllOffsets K.OffsetCommit consumer
  }
