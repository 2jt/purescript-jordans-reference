module ToC.Domain.Types (Env,LogLevel(..)) where

import Prelude

import Data.List (List)
import Data.Maybe (Maybe)
import Data.Tree (Tree)
import ToC.Core.FileTypes (HeaderInfo)
import ToC.Core.Paths (AddPath, FilePath, WebUrl, UriPath)
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

-- | The amount and type of information to log.
data LogLevel
  = Error
  | Info
  | Debug

derive instance eqLogLevel :: Eq LogLevel
derive instance ordLogLevel :: Ord LogLevel
