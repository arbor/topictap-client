{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeFamilies           #-}

module Arbor.TopicTap.Lens where

import Arbor.TopicTap.Chunk
import Control.Lens

makeFields ''Chunk
