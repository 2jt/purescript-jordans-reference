# Identifying The Pattern

You will want to bookmark this page.

Generalizing the idea we discovered in the previous file into a pattern, we get something like this:
```purescript
program :: forall m
         . MonadState StateType m
        => MonadWriter NonOutputData m
     -- => other needed type classes here in any order...
        => m ProgramFinalOutputType
program = do
  -- use all the functions from the type classes

--  StateT state         monad output
-- "IndexN possibleInput monad typeClassOutput"
runProgram :: Index3 input3 (       -- bottom of the stack
                Index2 input2 (
                  Index1 input1 (
                    Index0 input0   -- =
                      Identity      -- | top of the stack (just a function)
                    output0         -- =
                  ) output1
                ) output2
              ) output3
        -- -> input0      -- =
        -- -> input1      -- | all needed initial
        -- -> input2      -- | args go here
        -- -> input3      -- =
           -> Tuple (
                Tuple (
                  Tuple (
                    Tuple (
                      computationOutput
                      output3
                    )
                    output2
                  )
                  output1
                )
                output0
              )
runProgram computation {- args -} =
  runIndex0 (                               -- top of the stack
    runIndex1T (
      runIndex2T (
        runIndex3T computation index3Args   -- bottom of the stack
      ) index2Args
    ) index1Args
  ) index0Args
```
