module Projects.ToC.API.AppM (AppM(..), runAppM) where

import Prelude

import Control.Monad.Reader.Trans (class MonadAsk, ReaderT, ask, asks, runReaderT)
import Data.Maybe (Maybe(..))
import Data.List (List(..), foldl, (:))
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Console as Console
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.FS.Stats as Stats
import Node.Path (FilePath)
import Projects.ToC.Core.FileTypes (DirectoryPath(..), PathType(..))
import Projects.ToC.Domain.BusinessLogic (class GetTopLevelDirs, class LogToConsole, class ReadPath, class WriteToFile, Env)
import Type.Equality (class TypeEquals, from)

newtype AppM a = AppM (ReaderT Env Aff a)

runAppM :: Env -> AppM ~> Aff
runAppM env (AppM m) = runReaderT m env

instance monadAskAppM :: TypeEquals e Env => MonadAsk e AppM where
  ask = AppM $ asks from

derive newtype instance functorAppM :: Functor AppM
derive newtype instance applicativeAppM :: Applicative AppM
derive newtype instance applyAppM :: Apply AppM
derive newtype instance bindAppM :: Bind AppM
derive newtype instance monadAppM :: Monad AppM
derive newtype instance monadEffectAppM :: MonadEffect AppM
derive newtype instance monadAffAppM :: MonadAff AppM

instance logToConsoleAppM :: LogToConsole AppM where
  log :: String -> AppM Unit
  log msg = liftEffect $ Console.log msg

instance readPathAppM :: ReadPath AppM where
  readDir :: FilePath -> AppM (Array FilePath)
  readDir path =
    liftAff do
      FS.readdir path

  readFile :: FilePath -> AppM String
  readFile path =
    liftAff do
      FS.readTextFile UTF8 path

  readPathType :: FilePath -> AppM (Maybe PathType)
  readPathType path =
    liftAff do
      stat <- FS.stat path
      pure $
        if Stats.isDirectory stat
          then Just Dir
        else if Stats.isFile stat
          then Just File
        else Nothing

instance writeToFileAppM :: WriteToFile AppM where
  writeToFile :: String -> AppM Unit
  writeToFile content = do
    env <- ask
    liftAff do
      FS.writeTextFile UTF8 env.outputFile content

instance getTopLevelDirsAppM :: GetTopLevelDirs AppM where
  getTopLevelDirs :: AppM (List DirectoryPath)
  getTopLevelDirs = do
    env <- ask
    liftAff do
      paths <- FS.readdir env.rootDir
      foldl (\listInAff path -> do
        let fullPath = env.rootDir <> path
        stat <- FS.stat fullPath
        if (Stats.isDirectory stat && env.matchesTopLevelDir path)
          then
            (\list -> (DirectoryPath path) : list) <$> listInAff
          else
            listInAff
      ) (pure Nil) paths

      {- Note: The above "foldl" code could have also been written like this:
      foldl (\listInAff path -> do
        let fullPath = env.rootDir <> path
        ifM
          ((\s -> Stats.isDirectory s && env.matchesTopLevelDir path) <$> FS.stat fullPath)
          ((\list -> (DirectoryPath path) : list) <$> listInAff)
          listInAff
      ) (pure Nil) paths
      -}
