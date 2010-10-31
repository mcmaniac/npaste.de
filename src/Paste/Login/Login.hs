{-# OPTIONS_GHC -F -pgmFtrhsx #-}

module Paste.Login.Login
    ( loginPerform
    , loginMain
    ) where

import Control.Monad
import Control.Monad.Trans
import Data.Convertible
import Data.Maybe (fromMaybe)
import HSP
import Happstack.Server
import Happstack.State
import System.Time

import Happstack.Auth
import qualified Happstack.Auth        as Auth

import Paste.View
import Paste.Types
import Users.State


--------------------------------------------------------------------------------
-- | Show main login form

loginMain :: ServerPart Response
loginMain = do

    login <- getLogin
    uname <- fmap (either (const Nothing) Just) . getDataFn . body $ look "name"
    pwd   <- fmap (either (const Nothing) Just) . getDataFn . body $ look "password"
    case login of

         NotLoggedIn  -> htmlBody [loginFormHsp uname pwd Nothing]
         LoggedInAs _ -> htmlBody [alreadyLoggedInHsp]

loginFormHsp :: Maybe String -> Maybe String -> Maybe String -> HSP XML
loginFormHsp uname pwd err =
    <div id="main">
        <h1>Login</h1>
        <p>Enter your name and password below:</p>
        <% (\e -> <p class="error">Error: <% e %></p>) `fmap` err %>

        <form id="login-form" action="/?view=login" method="post">
            <p><span class="desc">Username:</span><input type="text" name="name" value=(fromMaybe "" uname) /></p>
            <p><span class="desc">Password:</span><input type="password" name="password" value=(fromMaybe "" pwd) /></p>
            <p><input type="submit" name="submit" value="Login" /></p>
        </form>
    </div>

alreadyLoggedInHsp :: HSP XML
alreadyLoggedInHsp =
    <div id="main">
        <h1>Already Logged In</h1>
        <p>You are already logged in. Click here to <a href="/?view=logout">logout</a>.</p>
    </div>


--------------------------------------------------------------------------------
-- | Perform login

loginPerform :: ServerPart Response
loginPerform = do

    methodM POST

    -- login <- getLogin
    -- guard $ NotLoggedIn /= login

    uname <- either (const "") id `fmap` getDataFn (body $ look "name")
    pwd   <- either (const "") id `fmap` getDataFn (body $ look "password")

    guard . not $ null uname || null pwd

    user  <- query $ Auth.GetUser (Auth.Username uname)
    case user of

         Just Auth.User { Auth.userid = uid, Auth.userpass = salted } | Auth.checkSalt pwd salted == True -> do

             skey <- update $ Auth.NewSession (Auth.SessionData uid (Auth.Username uname))
             -- let u' = convert u
             -- performLogin (60 * 60 * 24) u' $ do
             -- Just skey <- getSessionKey
             addCookie (MaxAge $ 60 * 60 * 24 * 31) -- 1 month
                       (mkCookie "session-key" (let Auth.SessionKey i = skey in show i))

             now  <- liftIO getClockTime
             host <- rqPeer `fmap` askRq
             update $ SetSessionData skey (host, now)

             htmlBody' (LoggedInAs skey) [loginSuccessHsp uname]

         Just _  -> htmlBody' NotLoggedIn [loginFormHsp (Just uname) (Just pwd) (Just "Wrong password.")]
         Nothing -> htmlBody' NotLoggedIn [loginFormHsp (Just uname) (Just pwd) (Just "Wrong username.")]

loginSuccessHsp :: String -> HSP XML
loginSuccessHsp uname =
    <div id="main">
        <h1>Login successful</h1>
        <p>You are now logged in as <% uname %>.</p>
    </div>
