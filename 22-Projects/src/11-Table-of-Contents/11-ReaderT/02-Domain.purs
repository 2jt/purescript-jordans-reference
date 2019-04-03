module ToC.ReaderT.Domain
  ( Env
  , program
  , class ReadPath, readDir, readFile, readPathType
  , class WriteToFile, writeToFile
  , class Logger, log, logInfo, logError, logDebug
  , class VerifyLink, verifyLink
  , LogLevel(..)
  ) where

import Prelude

import Control.Monad.Reader (class MonadAsk, ask)
import Data.Array (catMaybes, intercalate, sortBy)
import Data.List (List)
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Data.Tree (Tree, showTree)
import ToC.Core.FileTypes (HeaderInfo)
import ToC.Core.Paths (FilePath, PathType(..), WebUrl, UriPath, AddPath)
import ToC.Core.RenderTypes (TopLevelContent)

-- | The Environment type specifies the following ideas:
-- | - a backend-independent way to create file system paths. For example,
-- |   one could run the program via Node, C++, C, Erlang, or another such
-- |   backend:
-- |    - `rootUri`
-- |    - `addPath`
-- |    - `outputFile`
-- | - functions which determine which directories and files to include/exclude:
-- |    - `matchesTopLevelDir`
-- |    - `includeRegularDir`
-- |    - `includeFile`
-- | - functions for parsing a file's content. One could use a different parser
-- |   library is so desired:
-- |    - `parseFile`
-- | - functions that render the conten. One could render it as Markdown or
-- |   as HTML:
-- |    - `renderToC`
-- |    - `renderTopLevel`
-- |    - `renderDir`
-- |    - `renderFile`
-- | - A level that indicates how much information to log to the console
-- |    - `logLevel`
type Env = { rootUri :: UriPath
           , addPath :: AddPath
           , outputFile :: FilePath
           , sortPaths :: FilePath -> FilePath -> Ordering
           , matchesTopLevelDir :: FilePath -> Boolean
           , includeRegularDir :: FilePath -> Boolean
           , includeFile :: FilePath -> Boolean
           , parseFile :: FilePath -> String -> List (Tree HeaderInfo)
           , renderToC :: Array TopLevelContent -> String
           , renderTopLevel :: FilePath -> Array String -> TopLevelContent
           , renderDir :: Int -> FilePath -> Array String -> String
           , renderFile :: Int -> Maybe WebUrl -> FilePath -> List (Tree HeaderInfo) -> String
           , logLevel :: LogLevel
           }

program :: forall m.
           Monad m =>
           MonadAsk Env m =>
           Logger m =>
           ReadPath m =>
           WriteToFile m =>
           VerifyLink m =>
           m Unit
program = do
  output <- renderFiles
  logInfo "Finished rendering files. Now writing to file."
  writeToFile output
  logInfo "Done."

-- | Recursively walks the file tree, starting at the root directory
-- | and renders each file and directory that should be included.
renderFiles :: forall m.
               Monad m =>
               MonadAsk Env m =>
               Logger m =>
               ReadPath m =>
               WriteToFile m =>
               VerifyLink m =>
               m String
renderFiles = do
  env <- ask
  paths <- readDir env.rootUri.fs
  let sortedPaths = sortBy env.sortPaths paths
  logDebug $ "All possible top-level directories\n" <> intercalate "\n" sortedPaths
  sections <- catMaybes <$> renderSectionsOrNothing env sortedPaths
  pure $ env.renderToC sections

  where
    -- | More or less maps the unrendered top-level directory array into
    -- | rendered top-level directory array.
    renderSectionsOrNothing :: Env -> Array FilePath -> m (Array (Maybe TopLevelContent))
    renderSectionsOrNothing env paths =
      -- the function that follows 'parTraverse' is done in parallel
      paths # traverse \topLevelPath -> do
        let fullPath = env.addPath env.rootUri topLevelPath
        pathType <- readPathType fullPath.fs
        case pathType of
          Just Dir | env.matchesTopLevelDir topLevelPath -> do
            logDebug $ "Rendering top-level directory (start): " <> fullPath.fs
            output <- renderTopLevelSection fullPath topLevelPath
            logDebug $ "Rendering top-level directory (done) : " <> fullPath.fs
            pure $ Just output
          _ -> pure $ Nothing

-- | Renders a single top-level directory, using its already-rendered
-- | child paths.
renderTopLevelSection :: forall m.
                         Monad m =>
                         MonadAsk Env m =>
                         Logger m =>
                         ReadPath m =>
                         WriteToFile m =>
                         VerifyLink m =>
                         UriPath -> FilePath -> m TopLevelContent
renderTopLevelSection topLevelFullPath topLevelPathSegment = do
  env <- ask
  unparsedPaths <- readDir topLevelFullPath.fs
  let sortedPaths = sortBy env.sortPaths unparsedPaths
  renderedPaths <- catMaybes <$> traverse (renderPath 0 topLevelFullPath) sortedPaths
  pure $ env.renderTopLevel topLevelPathSegment renderedPaths

-- | Renders the given path, whether it is a directory or a file.
renderPath :: forall m.
              Monad m =>
              MonadAsk Env m =>
              Logger m =>
              ReadPath m =>
              WriteToFile m =>
              VerifyLink m =>
              Int -> UriPath -> FilePath -> m (Maybe String)
renderPath depth fullParentPath childPath = do
  env <- ask
  let fullChildPath = env.addPath fullParentPath childPath
  pathType <- readPathType fullChildPath.fs
  case pathType of
    Just Dir
      | env.includeRegularDir childPath -> do
          logDebug $ "Rendering directory (start): " <> fullChildPath.fs
          output <- renderDir depth fullChildPath childPath
          logDebug $ "Rendering directory (done) : " <> fullChildPath.fs
          pure $ Just output
      | otherwise                       -> do
          logDebug $ "Excluding directory: " <> fullChildPath.fs
          pure Nothing
    Just File
      | env.includeFile childPath -> do
          logDebug $ "Rendering File (start): " <> fullChildPath.fs
          output <- renderFile depth fullChildPath childPath
          logDebug $ "Rendering File (done) : " <> fullChildPath.fs
          pure $ Just output
      | otherwise                 -> do
          logDebug $ "Excluding File: " <> fullChildPath.fs
          pure Nothing
    _ -> do
      logInfo $ "Unknown path type: " <> fullChildPath.fs
      pure Nothing

-- | Renders the given directory and all of its already-rendered child paths
renderDir :: forall m.
             Monad m =>
             MonadAsk Env m =>
             Logger m =>
             ReadPath m =>
             WriteToFile m =>
             VerifyLink m =>
             Int -> UriPath -> FilePath -> m String
renderDir depth fullDirPath dirPathSegment = do
  env <- ask
  unparsedPaths <- readDir fullDirPath.fs
  let sortedPaths = sortBy env.sortPaths unparsedPaths
  renderedPaths <- catMaybes <$> traverse (renderPath (depth + 1) fullDirPath) sortedPaths
  pure $ env.renderDir depth dirPathSegment renderedPaths

-- | Renders the given file and all of its headers
renderFile :: forall m.
              Monad m =>
              MonadAsk Env m =>
              Logger m =>
              ReadPath m =>
              WriteToFile m =>
              VerifyLink m =>
              Int -> UriPath -> FilePath -> m String
renderFile depth fullFilePath filePathSegment = do
  let fullFsPath = fullFilePath.fs
  let fullUrl = fullFilePath.url
  linkWorks <- verifyLink fullUrl
  url <- if linkWorks
          then do
            logInfo $ "Successful link for: " <> fullFsPath
            pure $ Just fullUrl
          else do
            logError $ "File with invalid link: " <> fullFsPath
            logError $ "Link was: " <> fullUrl
            pure Nothing
  content <- readFile fullFsPath
  env <- ask
  let headers = env.parseFile filePathSegment content
  logDebug $ "Headers for file:"
  logDebug $ intercalate "\n" (showTree <$> headers)
  pure $ env.renderFile depth url filePathSegment headers

-- | A monad that has the capability of determining the path type of a path,
-- | reading a directory for its child paths, and reading a file for its
-- | content.
class (Monad m) <= ReadPath m where
  readDir :: FilePath -> m (Array FilePath)

  readFile :: FilePath -> m String

  readPathType :: FilePath -> m (Maybe PathType)

-- | A monad that has the capability of writing content to a given file path.
class (Monad m) <= WriteToFile m where
  writeToFile :: String -> m Unit

-- | A monad that has the capability of sending HTTP requests, which are
-- | used to verify that the URL is valid and receives a 200 OK code.
class (Monad m) <= VerifyLink m where
  verifyLink :: WebUrl -> m Boolean

-- | The amount and type of information to log.
data LogLevel
  = Error
  | Info
  | Debug

derive instance eqLogLevel :: Eq LogLevel
derive instance ordLogLevel :: Ord LogLevel

-- | A monad that has the capability of logging messages, whether to the
-- | console or a file.
class (Monad m) <= Logger m where
  log :: LogLevel -> String -> m Unit

-- | Logs a message using the Error level
logError :: forall m. Logger m => String -> m Unit
logError msg = log Error msg

-- | Logs a message using the Info level
logInfo :: forall m. Logger m => String -> m Unit
logInfo msg = log Info msg

-- | Logs a message using the Debug level
logDebug :: forall m. Logger m => String -> m Unit
logDebug msg = log Debug msg
