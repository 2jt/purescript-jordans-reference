-- | This modules simply re-exports all the underlying 'Core' submodules
module Games.RandomNumber.Core (module Exports) where

import Games.RandomNumber.Core.Bounded (
  Bounds, mkBounds, unBounds, totalPossibleGuesses
, BoundsCheckError(..), BoundsCreationError(..)
, Guess, mkGuess, guessEqualsRandomInt, (==#)
, RandomInt, mkRandomInt
) as Exports

import Games.RandomNumber.Core.RemainingGuesses (
  RemainingGuesses, mkRemainingGuesses, unRemainingGuesses
, decrement, outOfGuesses
, RemainingGuessesCreationError(..)
) as Exports

import Games.RandomNumber.Core.GameTypes (
  GameInfo, mkGameInfo, GameResult(..)
) as Exports
