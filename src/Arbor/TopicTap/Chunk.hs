module Arbor.TopicTap.Chunk where

import Data.Text            (Text)
import Kafka.Consumer.Types
import Kafka.Types

data Chunk = Chunk
  { _chunkTopicName      :: TopicName
  , _chunkPartitionId    :: PartitionId
  , _chunkTimestampChunk :: Timestamp
  , _chunkOffsetFirst    :: Offset
  , _chunkTimestampFirst :: Timestamp
  , _chunkOffsetMax      :: Offset
  , _chunkTimestampLast  :: Timestamp
  , _chunkS3Uri          :: Text
  } deriving (Eq, Show)
