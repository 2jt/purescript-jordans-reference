-- | Provides a CLI interface to our program via the Yargs library.
module ToC.Infrastructure.Yargs (runProgramViaCLI) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (elem, notElem)
import Data.List (List(..))
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), length, split, take)
import Data.String.Utils (endsWith)
import Data.Tree (Tree)
import Effect (Effect)
import Node.Path (extname, sep)
import Node.Yargs.Applicative (flag, runY, yarg)
import Node.Yargs.Setup (YargsSetup, example, usage)
import ToC.API (ProductionEnv)
import ToC.Core.FileTypes (HeaderInfo)
import ToC.Core.GitHubLinks (renderGHPath)
import ToC.Core.Paths (FilePath, IncludeablePathType(..), WebUrl, addPath')
import ToC.Domain.Parser (extractMarkdownHeaders, extractPurescriptHeaders)
import ToC.Domain.Renderer.MarkdownRenderer (renderDir, renderFile, renderToC, renderTopLevel)
import ToC.Domain.Types (LogLevel(..))
import ToC.Infrastructure.OSFFI (endOfLine)

usageAndExample :: YargsSetup
usageAndExample =
       usage "Produces a Table of Contents file in Markdown whose links \
             \refer to a GitHub repo's corresponding file."
    <> example
         "node 22-Projects/dist/table-of-contents/ghtoc.js \
            \-r \".\" -o \"./table-of-contents.md\""
         "Produces a Table of Contents file in the shell's current working \
         \directory."
    <> example
         "node 22-Projects/dist/table-of-contents/ghtoc.js \
            \-r \".\" -o \"./table-of-contents.md\" --log-level info"
         "Runs the program with the log level set to 'info'"
    <> example
         "node ghtoc.js -r \"/home/user/purescript-jordans-reference/\" \
         \-o \"/home/user/purescript-jordans-reference/table-of-contents.md\""
         "Produces a Table of Contents file using absolute paths."
    <> example
         "node 22-Projects/dist/table-of-contents/ghtoc.js \
            \-r \".\" -o \"./table-of-contents.md\" \
            \-ref \"development\""
         "Produces a Table of Contents file whose hyperlinks use the \
         \'development' branch name instead of `latestRelease`."

runProgramViaCLI :: (ProductionEnv -> Effect Unit)
                 -> Effect Unit
runProgramViaCLI programThatUsesProdEnv = do
  runY usageAndExample $ (setupEnvThenRun programThatUsesProdEnv)
        <$> yarg "r" ["root-dir"]
              (Just "The local computer's file path to the root directory that \
                    \contains this repository.")
              (Right "You need to provide the path to the root directory.") true
        <*> yarg "o" ["output-file"]
              (Just "The path of the file to which to write the \
                    \program's Table of Contents output")
              (Right "You must specify a path for the output of the program") true
        <*> yarg "t" ["exclude-top-level-dirs"]
              (Just "An array of top-level directories (case-sensitive) to exclude. \
                    \By default, this is '.git', '.github', '.travis' and 'output'")
              (Left [ ".git", ".github", ".procedures", ".travis", "output"]) true
        <*> yarg "d" ["exclude-regular-dirs"]
              (Just "An array of directories (case-sensitive) to exclude \
                    \when recursively examining the directories and files of \
                    \the top-level directories.")
              (Left
                -- PS-related directories
                [ ".spago", "generated-docs", ".psci_modules",  "output", "tmp"
                -- NPM and Parcel related things
                , ".cache", "node_modules", "dist"
                -- project-specific files
                , "benchmark-results"
                -- repo-specific files
                , "assets", "modules-used-in-examples"
                ]) true
        <*> yarg "f" ["include-files-with-extensions"]
              (Just "An array of file extensions that indicate which files \
                    \should be included in the Table of Contents. By default, \
                    \this is '.purs', '.md', and '.js'")
              (Left [ ".purs", ".md", ".js"]) true
        <*> yarg "u" ["github-username"]
              (Just "The username part of the GitHub repo's URL. By default, \
                    \this is 'JordanMartinez'")
              (Left "JordanMartinez") true
        <*> yarg "p" ["github-project"]
              (Just "The project name part of the GitHub repository's URL. \
                    \By default, this is 'purescript-jordans-reference'")
              (Left "purescript-jordans-reference") true
        <*> yarg "ref" ["github-reference"]
              (Just "The name of the project's branch or tag to use when \
                    \producing the hyperlinks to files and their headers. \
                    \By default, this is 'development'")
              (Left "development") true
        <*> yarg "log-level" []
              (Just "The amount of information to log to the screen. \
                    \Valid options are 'error', 'info', and 'debug'. \
                    \Default is 'error'.")
              (Left "error") true
        <*> flag "skip-url-verification" []
              (Just "Do not verify whether hyperlinks work, \
                    \but still render the ToC file with them.")

setupEnvThenRun :: (ProductionEnv -> Effect Unit) ->
                   FilePath -> FilePath ->
                   Array String -> Array String -> Array String ->
                   String -> String -> String ->
                   String -> Boolean ->
                   Effect Unit
setupEnvThenRun runProgramUsingEnv
             rootDirectory outputFile
             excludedTopLevelDirs excludedRegularDir includedFileExtensions
             ghUsername ghProjectName ghBranchName
             logLevel skipVerification
             =
    runProgramUsingEnv
      { rootUri: { fs: rootDir
                 , url: rootURL
                 }
      , addPath: addPath' sep
      , includePath: includePath
      , outputFile: outputFile
      , sortPaths: sortPaths
      , parseFile: parseFile
      , renderToC: renderToC
      , renderTopLevel: renderTopLevel
      , renderDir: renderDir
      , renderFile: renderFile
      , logLevel: level
      , shouldVerifyLinks: not skipVerification
      }
  where
    rootDir :: FilePath
    rootDir =
        if endsWith sep rootDirectory
          then take ((length rootDirectory) - 1) rootDirectory
          else rootDirectory

    rootURL :: WebUrl
    rootURL = renderGHPath { username: ghUsername
                             , repo: ghProjectName
                             , ref: ghBranchName
                             }

    includePath :: IncludeablePathType -> FilePath -> Boolean
    includePath pathType path = case pathType of
      TopLevelDirectory -> notElem path excludedTopLevelDirs
      NormalDirectory -> notElem path excludedRegularDir
      A_File -> elem (extname path) includedFileExtensions

    sortPaths :: FilePath -> FilePath -> Ordering
    sortPaths l r =
      -- ensure that ReadMe files always appear first
      if l == "ReadMe.md" || l == "Readme.md"
        then LT
      else if r == "ReadMe.md" || r == "Readme.md"
        then GT
      else compare l r

    parseFile :: FilePath -> String -> List (Tree HeaderInfo)
    parseFile filePath content =
        case extname filePath of
          ".purs" -> extractPurescriptHeaders $ split (Pattern endOfLine) content
          ".md" -> extractMarkdownHeaders $ split (Pattern endOfLine) content
          _ -> Nil

    level :: LogLevel
    level =
        case logLevel of
          "info" -> Info
          "debug" -> Debug
          _ -> Error
