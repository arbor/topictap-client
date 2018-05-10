{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TemplateHaskell        #-}

module Arbor.TopicTap.Lens where

import Arbor.TopicTap.Chunk
import Control.Arrow
import Control.Lens
import Data.Text            (Text)
import Text.Read

import qualified Data.Text            as T
import qualified Network.AWS.DynamoDB as DDB

makeFields ''Chunk

textRs :: (Read a, Show a) => Prism Text Text a a
textRs = prism (T.pack . show) (\v -> left (const v) (readEither (T.unpack v)))

maybeTextRs :: (Read a, Show a) => Prism (Maybe Text) (Maybe Text) a a
maybeTextRs = _Just . textRs

avnRs :: (Read a, Show a) => Traversal DDB.AttributeValue DDB.AttributeValue a a
avnRs = DDB.avN . maybeTextRs

avnInt :: Traversal DDB.AttributeValue DDB.AttributeValue Int Int
avnInt = avnRs

avnDouble :: Traversal DDB.AttributeValue DDB.AttributeValue Double Double
avnDouble = avnRs
