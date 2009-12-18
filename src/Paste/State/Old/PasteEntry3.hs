{-# LANGUAGE TemplateHaskell, TypeFamilies, DeriveDataTypeable,
    FlexibleInstances, MultiParamTypeClasses, FlexibleContexts,
    TypeSynonymInstances, UndecidableInstances
    #-}

module Paste.State.Old.PasteEntry3 ( PasteEntry (..) ) where

import Happstack.Data
import Happstack.Server.HTTP.Types      (Host)
import Happstack.State.ClockTime        (ClockTime (..))

import Users.State                      (User (..))
import Paste.State.ID                   (ID (..))
import Paste.State.Content              (Content (..))

import qualified Data.ByteString as BS
import qualified Paste.State.Old.PasteEntry2 as Old

$(deriveAll [''Show, ''Eq, ''Ord, ''Default]
    [d|

        -- | PasteEntry: Simple paste entry
        data PasteEntry = PasteEntry
                    { user      :: Maybe User
                    , pId       :: ID
                    , date      :: ClockTime
                    , content   :: Content
                    , md5hash   :: BS.ByteString
                    , filetype  :: Maybe String
                    , postedBy  :: Host
                    }
    |])

$(deriveSerialize ''PasteEntry)
instance Version PasteEntry where
    -- mode = Versioned 2 Nothing
    mode = extension 3 (Proxy :: Proxy Old.PasteEntry)

instance Migrate Old.PasteEntry PasteEntry where
    migrate (Old.PasteEntry u i d c md f) = PasteEntry u i d c md f ("", 0)
