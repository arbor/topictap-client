module Arbor.TopicTap.Kafka
( createKafkaConsumer
, closeKafkaConsumer
)
where

import Control.Arrow          (left)
import Control.Monad.IO.Class (MonadIO)
import Data.ByteString        (ByteString)
import Data.IORef             (IORef)
import Data.Monoid            ((<>))
import Kafka.Consumer         (ConsumerGroupId, ConsumerRecord, KafkaConsumer, RebalanceEvent, TopicName, TopicPartition)

import qualified Kafka.Consumer as K

import Arbor.TopicTap.Error   (TopicTapError (..))
import Arbor.TopicTap.Options (KafkaConfig (..))

createKafkaConsumer :: MonadIO m
                    => KafkaConfig
                    -> TopicName
                    -> ConsumerGroupId
                    -> (RebalanceEvent -> IO ())
                    -> m (Either TopicTapError KafkaConsumer)
createKafkaConsumer conf topic cgroup onRebalance =
  let
    props =  K.brokersList [_kcBroker conf]
          <> K.groupId cgroup
          <> K.queuedMaxMessagesKBytes (_kcQueuedMaxMsgKBytes conf)
          <> K.noAutoCommit
          <> K.setCallback (K.rebalanceCallback (const onRebalance))
    sub = K.topics [topic]
  in left KafkaErr <$> K.newConsumer props sub


closeKafkaConsumer :: MonadIO m => KafkaConsumer -> m (Maybe TopicTapError)
closeKafkaConsumer consumer =
  fmap (fmap KafkaErr) (K.closeConsumer consumer)
