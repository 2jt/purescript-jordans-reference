module Syntax.Record.Basic where

import Prelude

-- Records have a different kind than "Type".

-- "# Type" stands for a "row" of types.
-- It uses a special kind called "row kinds" to indicate that there will be an
-- N-sized number of types that are known at compile time.
-- Row kinds will be covered more fully in the Type-Level Programming Syntax
-- folder.

type Example_of_an_Empty_Row = ()
type Example_of_a_Single_Row = (fieldName :: ValueType)
type Example_of_a_Multiple_Rows = (first :: ValueType, second :: ValueType)

type PS_Keywords_Can_Be_Field_Names = (data :: ValueType, type :: ValueType, class :: ValueType)

data Record_ -- # Type -> Type

-- Think of records as a unordered named TupleN
type RecordType_Desugared = Record ( field1 :: String
                                -- , ...
                                   , fieldN :: Int
                                   , function :: (String -> String)
                                   )
-- However, there is syntax sugar for writing this:
-- "Record ( rows )" becomes "{ rows }"
type RecordType = { field1 :: String
               -- , ...
                  , fieldN :: Int
                  , function :: String -> String
                  }

getField :: RecordType -> String
getField obj = obj.field1

-- We can create a record using the "{ label: value }" syntax...
createRec_colonSyntax :: RecordType
createRec_colonSyntax = { field1: "value", fieldN: 1, function: (\x -> x) }

-- We can also create it using the "names exist in immediate context" syntax

createRec_immediateContextSyntax :: RecordType
createRec_immediateContextSyntax = { field1, fieldN, function }
  where
    field1 = "value"
    fieldN = 1
    function = \x -> x

-- We can also create it using the "label names exist in external context" syntax
-- Given the below record type...
type PersonRecord = { username :: String
                    , age :: Int
                    , isCool :: String -> Boolean
                    }
-- ... and some values/functions with the same name as that record's fields...
username :: String
username = "Bob"

age :: Int
age = 4

isCool :: String -> Boolean
isCool _ = true

-- ... the compiler will infer below that 'username' should be "Bob"
-- because `username` is a value that exists in this module.
-- Note: this syntax won't pick up things that exist in other files.
createRec_externalContextSyntax :: PersonRecord
createRec_externalContextSyntax = { username, age, isCool }


-- We can update a record using syntax sugar:
setField :: RecordType -> String -> RecordType
setField rec string = rec { field1 = string }

-- Some syntax for inline functions:

--    \field1 field2 -> rec { field1: field1, field2: field2 }
-- ... is the same as ...
--                      rec { field1: _     , field2: _      }

--    \rec field1 {- fieldN -} -> rec { field1: field1 {- , fieldN: fieldN -} }
-- ... is the same as ...
--                                _   { field1: _      {- , fieldN: _      -} }

type NestedRecordType = { person :: { skills :: { name :: String } } }

nestedRecordUpdate :: String -> NestedRecordType -> NestedRecordType
nestedRecordUpdate name p = p { person { skills { name = "newName" } } }

syntaxReminder :: String
syntaxReminder = """

Don't confuse the two operators that go in-between field and value!

"field OPERATOR value" where OPERATOR is
  "=" means "update the field of a record that already exists":
          record { field = newValue }
  ":" means "create a new record by specifying the field's value":
                 { field: initialValue }
"""

-- We can also pattern match on a record. The field names must match
-- the field names of the record
patternMatch_allLabels :: Int
patternMatch_allLabels =
  let { field1, field2 } = { field1: 3, field2: 5 }
  in field1 + field2

patternMatch_someLabels :: String
patternMatch_someLabels =
  -- notice how we don't include 'field2' here
  -- in the pattern match
  let { field1 } = { field1: "a", field2: "b" }
  in field1

-- needed to compile
type ValueType = String
