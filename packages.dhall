let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/prepare-0.14/src/packages.dhall

let additions =
      { benchotron =
        { dependencies =
          [ "arrays"
          , "exists"
          , "profunctor"
          , "strings"
          , "quickcheck"
          , "lcg"
          , "transformers"
          , "foldable-traversable"
          , "exceptions"
          , "node-fs"
          , "node-buffer"
          , "node-readline"
          , "datetime"
          , "now"
          ]
        , repo = "https://github.com/JordanMartinez/purescript-benchotron.git"
        , version = "v8.0.0"
        }
      }

in  (upstream // additions)
      with metadata = upstream.metadata // { version = "v0.14.0-rc5" }
