{-# LANGUAGE NamedFieldPuns #-}
module Arbor.TopicTap.TConsumer
(
-- | Exported types
  TConsumer
, ConsumerGroupId(..)
, KafkaConfig
, ConsumerRecord(..)
, Timeout
, RebalanceEvent(..)
, TopicName(..)
, TopicPartition(..)
, TopicTapError(..)
-- | Consumer operations
, createConsumer, closeConsumer
, storeOffsets, storeMessageOffset
, commitOffsets
, poll
)
where

import Control.Arrow          (left)
import Control.Monad          (mapM, void)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.ByteString        (ByteString)
import Data.IORef             (IORef, newIORef, readIORef, writeIORef)
import Data.Monoid            ((<>))
import Kafka.Consumer         (ConsumerGroupId, ConsumerRecord, KafkaConsumer, RebalanceEvent, Timeout, TopicName, TopicPartition)

import qualified Kafka.Consumer as K

import Arbor.TopicTap.Error
import Arbor.TopicTap.Kafka
import Arbor.TopicTap.Options

data TConsumer m = TConsumer
  { tcKafka :: KafkaConsumer
  , tcFuncs :: IORef (TC m)
  }

data TC m = TC
  { pollMessage :: Timeout -> m (Either TopicTapError (ConsumerRecord (Maybe ByteString) (Maybe ByteString)))
  , close       :: m (Maybe TopicTapError)
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
  mapM mkTConsumer kafka

-- | Closes the TopicTap consumer.
closeConsumer :: MonadIO m => TConsumer m -> m (Maybe TopicTapError)
closeConsumer TConsumer{tcKafka, tcFuncs} = do
  tc    <- liftIO $ readIORef tcFuncs
  tcErr <- close tc
  case tcErr of
    Just err -> pure (Just err)
    Nothing  -> closeKafkaConsumer tcKafka

-- | Stores offsets to be committed later by 'commitOffsets'
storeOffsets :: MonadIO m
             => TConsumer m
             -> [TopicPartition]
             -> m (Maybe TopicTapError)
storeOffsets TConsumer{tcKafka} =
  fmap (fmap KafkaErr) . K.storeOffsets tcKafka

-- | Stores specific message offset to be committed later
-- when 'commitOffsets' is called
storeMessageOffset :: MonadIO m
                   => TConsumer m
                   -> ConsumerRecord k v
                   -> m (Maybe TopicTapError)
storeMessageOffset TConsumer{tcKafka} cr =
  fmap KafkaErr <$> K.storeOffsetMessage tcKafka cr

--  | Commits all the stored offsets
commitOffsets :: MonadIO m
              => TConsumer m
              -> m (Maybe TopicTapError)
commitOffsets TConsumer{tcKafka} =
  fmap KafkaErr <$> K.commitAllOffsets K.OffsetCommit tcKafka

-- | Polls one message from the consumer.
poll :: MonadIO m
     => TConsumer m
     -> Timeout
     -> m (Either TopicTapError (ConsumerRecord (Maybe ByteString) (Maybe ByteString)))
poll consumer@TConsumer{tcKafka, tcFuncs} timeout = do
  emsg <- liftIO (readIORef tcFuncs) >>= flip pollMessage timeout
  case emsg of
    Right msg        -> pure (Right msg)
    Left EndOfBackup ->
      -- Perform switch, but propagate end of backup to the client
      switchToKafka consumer >> pure (Left EndOfBackup)
    Left err         -> pure (Left err)

-------------------------------------------------------------------------------
switchToKafka :: MonadIO m => TConsumer m -> m (Either TopicTapError ())
switchToKafka consumer = do
  tc    <- liftIO (readIORef $ tcFuncs consumer)
  clRes <- close tc
  case clRes of
    Just err -> pure (Left err)
    Nothing  -> liftIO $ Right <$> writeIORef (tcFuncs consumer) (kafkaTC $ tcKafka consumer)

mkTConsumer :: MonadIO m => KafkaConsumer -> m (TConsumer m)
mkTConsumer consumer =
  liftIO $ TConsumer consumer <$> newIORef backupTC

-- Fake backup TC thing that always returns 'EndOfBackup' until implemented
backupTC :: MonadIO m => TC m
backupTC = TC
  { pollMessage = const $ pure (Left EndOfBackup)
  , close = pure Nothing
  }

kafkaTC :: MonadIO m => KafkaConsumer -> TC m
kafkaTC consumer = TC
  { pollMessage = fmap (left KafkaErr) . K.pollMessage consumer
  , close       = pure Nothing
  }
