module Arbor.TopicTap.Options
where

import Kafka.Consumer (BrokerAddress, Timeout)

data KafkaConfig = KafkaConfig
  { _kcBroker                :: BrokerAddress
  , _kcSchemaRegistryAddress :: String
  , _kcPollTimeoutMs         :: Timeout
  , _kcQueuedMaxMsgKBytes    :: Int
  , _kcDebugOpts             :: String
  } deriving (Show)
