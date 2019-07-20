module Syntax.MonadLikeTypeClasses
  ( class IxFunctor, imap, map
  , class IxApply, iapply, apply
  , class IxApplicative, ipure, pure
  , class IxBind, ibind, bind
  , class IxMonad
  ) where

import Data.Unit (Unit)

-- Requirement 1: type classes that are similar to Functor to Monad hierarchy
--  - ado requirements: Functor, Apply, and Applicative
--  - do requirements: Functor, Apply, Applicative, Bind, and Monad

class IxFunctor f where
  imap :: forall a b x. (a -> b) -> f x x a -> f x x b

class (IxFunctor f) <= IxApply f where
  iapply :: forall a b x y z. f x y (a -> b) -> f y z a -> f x z b

class (IxApply f) <= IxApplicative f where
  ipure :: forall a x. a -> f x x a

class (IxApply m) <= IxBind m where
  ibind ∷ forall a b x y z. m x y a -> (a -> m y z b) -> m x z b

class (IxApplicative m, IxBind m) <= IxMonad m

-- Requirement 2: define functions whose names correspond to the ones used
-- in the regular type classes: `map`, `apply`, 'pure', 'bind', and
-- 'discard' (for when bind returns 'unit')
map :: forall f a b x. IxFunctor f => (a -> b) -> f x x a -> f x x b
map = imap

apply :: forall f a b x y z. IxApply f => f x y (a -> b) -> f y z a -> f x z b
apply = iapply

pure :: forall f a x. IxApplicative f => a -> f x x a
pure = ipure

bind :: forall m a b x y z. IxBind m => m x y a -> (a -> m y z b) -> m x z b
bind = ibind

discard :: forall a x y z m. IxBind m => m x y a -> (a -> m y z Unit) -> m x z Unit
discard = ibind
