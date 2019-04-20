module RandomNumber.Run.Layered.ChangeImplementation where

import Prelude

import Data.Functor.Variant (on)
import Effect (Effect)
import Effect.Aff (runAff_)
import RandomNumber.Core (Bounds, Guess, mkGuess)
import RandomNumber.Run.Layered.HighLevelDomain (game, NOTIFY_USER, notifyUser, DEFINE_BOUNDS, _defineBounds, DEFINE_TOTAL_GUESSES, _defineTotalGuesses, GEN_RANDOM_INT, _genRandomInt, MakeGuessF(..), MAKE_GUESS, _makeGuess)
import RandomNumber.Run.Layered.LowLevelDomain (recursivelyRunUntilPure, GET_USER_INPUT, getUserInput, getIntFromUser, CREATE_RANDOM_INT, defineBoundsToAPI, defineTotalGuessesToAPI, genRandomIntToAPI)
import RandomNumber.Run.Layered.API (runLowLevelDomainInConsole)
import Node.ReadLine (createConsoleInterface, noCompletion, close)
import Run (Run, interpret, send)
import Type.Row (type (+))

-- | Normally, the user would input their guess and cannot confirm whether
-- | that is the user's final decision. In this interpretation, the user
-- | must confirm their guess or the computer will ask for it again.
makeAndConfirmGuess :: forall r. Bounds -> Run (NOTIFY_USER + GET_USER_INPUT + r) Guess
makeAndConfirmGuess bounds = do
  guess <- recursivelyRunUntilPure
    ((mkGuess bounds) <$> getIntFromUser "Your guess: ")
  notifyUser $ "You chose '" <> show guess <> "'"
  confirmation <- getUserInput "Are you sure? ('y' = yes; anything else = no): "
  case confirmation of
    "y" -> pure guess
    _ -> do
      notifyUser "You changed your mind. I'll ask again."
      makeAndConfirmGuess bounds

makeGuessToAPI_2 :: forall r. MakeGuessF ~> Run (NOTIFY_USER + GET_USER_INPUT + r)
makeGuessToAPI_2 (MakeGuessF bounds reply) = do
  guess <- makeAndConfirmGuess bounds
  pure (reply guess)

runHighLevelDomain_2 :: forall r
                      . Run (NOTIFY_USER +

                             DEFINE_BOUNDS + DEFINE_TOTAL_GUESSES + GEN_RANDOM_INT +
                             MAKE_GUESS +

                             GET_USER_INPUT + CREATE_RANDOM_INT + r)
                     ~> Run (NOTIFY_USER +

                             GET_USER_INPUT + CREATE_RANDOM_INT + r)
runHighLevelDomain_2 = interpret (
  send
    -- Before
 -- # on _makeGuess makeGuessToAPI

    -- After
    # on _makeGuess makeGuessToAPI_2

    -- Unchanged
    # on _defineBounds defineBoundsToAPI
    # on _defineTotalGuesses defineTotalGuessesToAPI
    # on _genRandomInt genRandomIntToAPI
  )

main :: Effect Unit
main = do
  interface <- createConsoleInterface noCompletion

  runAff_
    (\_ -> close interface)
    (runLowLevelDomainInConsole interface (runHighLevelDomain_2 game))
