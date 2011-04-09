{-# LANGUAGE TemplateHaskell, TypeFamilies, DeriveDataTypeable,
    FlexibleInstances, MultiParamTypeClasses, FlexibleContexts,
    UndecidableInstances, TypeOperators
    #-}
module App.State where

import Happstack.Data
import Happstack.State
import Paste.State (Paste)
import Users.State (Users)
import qualified Happstack.Auth as Auth

-- import qualified App.Old.State0 as Old

-- | top-level application state
-- in this case, the top-level state itself does not contain any state
deriveAll [''Show, ''Eq, ''Ord, ''Default] [d|

  data AppState = AppState

  |]

deriveSerialize ''AppState

instance Version AppState

-- |top-level application component
-- we depend on the GuestBook component
instance Component AppState where
    type Dependencies AppState = Auth.AuthState :+: Users :+: Paste :+: End
    initialValue = defaultValue

-- create types for event serialization
mkMethods ''AppState []
