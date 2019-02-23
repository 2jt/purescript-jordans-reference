module Projects.ToC.Main where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (elem, notElem)
import Data.List.Types (List(..))
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), split)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Node.Globals (__dirname)
import Node.Path (extname, normalize, sep)
import Node.Yargs.Applicative (flag, yarg, runY)
import Node.Yargs.Setup (example, usage)
import Projects.ToC.API.AppM (runAppM)
import Projects.ToC.Core.Paths (FilePath, addPath')
import Projects.ToC.Domain.BusinessLogic (Env, program, LogLevel(..))
import Projects.ToC.OSFFI (endOfLine)
import Projects.ToC.Parser (extractAllCodeHeaders, extractAllMarkdownHeaders)
import Projects.ToC.Renderer (RootURL(..), renderGHPath, renderToCFile)

main :: Effect Unit
main = do
  let usageAndExample =
           usage "Produces a Table of Contents file in Markdown whose links \
                 \refer to a GitHub repo's corresponding file."
        <> example
             "node 22-Projects/dist/table-of-contents/ghtoc.js \
                \-r \"../../../\" -o \"../../../table-of-contents.md\""
             "Produces a Table of Contents file using relative paths when run \
             \from the root directory."
        <> example
             "node ghtoc.js -ar \"/home/user/purescript-jordans-reference/\" \
             \-o \"/home/user/purescript-jordans-reference/table-of-contents.md\""
             "Produces a Table of Contents file using absolute paths when run \
             \from the `22-Projects/dist/table-of-contents/` directory."
        <> example
             "node 22-Projects/dist/table-of-contents/ghtoc.js \
                \-r \"../../../\" -o \"../../../table-of-contents.md\" \
                \-ref \"development\""
             "Produces a Table of Contents file whose hyperlinks use the \
             \'development' branch name instead of `latestRelease`."

  runY usageAndExample $ setupProgram
        <$> flag "a" ["use-absolute-paths"]
              (Just "Specifies that the `root-dir` and `output-file` arguments \
                    \are absolute paths, not paths that are relative to the \
                    \location of the bundled Javascript file outputted by the \
                    \compiler.")
        <*> yarg "r" ["root-dir"]
              (Just "The local computer's file path to the root directory that \
                    \contains this repository. For example, \
                    \'/home/user/purescript-jordans-reference/'")
              (Right "You need to provide the path to the root directory.") true
        <*> yarg "o" ["output-file"]
              (Just "The path of the file to which to write the \
                    \program's Table of Contents output")
              (Right "You must specify a path for the output of the program") true
        <*> yarg "t" ["exclude-top-level-dirs"]
              (Just "An array of top-level directories (case-sensitive) to exclude. \
                    \By default, this is '.git', '.github', '.travis' and 'output'")
              (Left [ ".git", ".github", ".travis", "output"]) true
        <*> yarg "d" ["exclude-regular-dirs"]
              (Just "An array of directories (case-sensitive) to exclude \
                    \when recursively examining the directories and files of \
                    \the top-level directories.")
              (Left
                -- PS-related directories
                [ ".psc-package", ".pulp-cache", ".psci_modules", "node_modules", "output", "tmp", "dist"
                -- project-specific files
                , "benchmark-results"
                -- repo-specific files
                , "images", "modules-used-in-examples", "resources"
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
                    \Default is 'info'.")
              (Left "info") true

setupProgram :: Boolean -> FilePath -> FilePath ->
                Array String -> Array String -> Array String ->
                String -> String -> String ->
                String ->
                Effect Unit
setupProgram useAbsolutePath rootDirectory outputPath
             excludedTopLevelDirs excludedRegularDir includedFileExtensions
             ghUsername ghProjectName ghBranchName
             logLevel
             = do
  let rootDir = if useAbsolutePath then rootDirectory else normalize $ __dirname <> sep <> rootDirectory
  let outputFile = if useAbsolutePath then outputPath else normalize $ __dirname <> sep <> outputPath
  let rootURL = renderGHPath { username: ghUsername
                             , repo: ghProjectName
                             , ref: ghBranchName
                             }
  let parseContent depth fileUrl extName content =
        case extName of
          ".purs" -> extractAllCodeHeaders depth fileUrl $ split (Pattern endOfLine) content
          ".md" -> extractAllMarkdownHeaders depth fileUrl $ split (Pattern endOfLine) content
          _ -> Nil
  let level =
        case logLevel of
          "info" -> Info
          "debug" -> Debug
          _ -> Error

  runProgram
    { rootUri: { fs: rootDir, url: rootURL }
    , addPath: addPath' sep
    , matchesTopLevelDir: (\path -> notElem path excludedTopLevelDirs)
    , includeRegularDir: (\path -> notElem path excludedRegularDir)
    , includeFile: (\path -> elem (extname path) includedFileExtensions)
    , parseContent: parseContent
    , renderToCFile: renderToCFile (RootURL rootURL)
    , outputFile: outputFile
    , logLevel: level
    }

runProgram :: Env -> Effect Unit
runProgram env = launchAff_ (runAppM env program)
