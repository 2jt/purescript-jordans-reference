# Type-Level Programming

This folder assumes you have read through and are familiar with `Type Level Syntax`. If you aren't, go and read through that first.

## Example

### A Problem

[Taken from this SO answer (last paragraph)](https://stackoverflow.com/a/24481747), type-level programming can be used to:
> restrict certain behavior at the value-level, manage resource finalization, or store more information about data-structures.

Let's explain a problem that highlights the third point: storing more information about data-structures. Below is one problem that occurs at the runtime that can be fixed with type-level programming.

An `Array` is a very fast data structure, but it's problematic because we never know the exact size of it at compile-time. Functions that operate on `Array` where its length/size is important are "partial functions," functions that may not give you a valid output but may instead throw an error. In other words, all your confidence that your code works as expected is thrown into the trash.

An example is getting an element in an `Array` at index `n`. If the array is empty or of size `n - 1`, the function can only throw an error. If it has `n` or more elements, it can return that element.
```purescript
elemAtIndex :: forall a. Partial => Int -> Array a -> a
elemAtIndex idx [] = Partial.crash "cannot get " <> show idx <> "th element of an empty array"
elemAtIndex index fullArray = unsafePartial $ unsafeIndex fullArray index
```

### A Solution

However, what if we could modify the type of `Array`, so that it included the size of that array at compile-time? Then, the type-checker could insure that the "elemAtIndex" function described above only receives correct arguments (i.e. specific types) that make the function "total," meaning the function will always return a valid output and never throw an error. If it receives an invalid argument, it results in a compiler error.

```purescript
-- This entire block of code is pseduo syntax and does not actually work!
-- Use it only to get the idea and don't hold onto any of the syntax used here.
elemAtIndex :: forall a n. HasElemAtIndex n => n -> IndexedArray n a
elemAtIndex index array = -- implementation

elemAtIndex 3 (IndexedArray 3 ["a", "b", "c", "d"]) -- "d"
elemAtIndex 0 (IndexedArray Empty []) -- compiler error!
```

This is exactly what the library [Vec](https://pursuit.purescript.org/packages/purescript-sized-vectors/3.1.0/docs/Data.Vec#t:Vec) does.

## Issues with Type-Level Programming

- While type-level programming may improve your program's runtime speed or further force you to use safe code, it will increase the time it takes to compile your program
- Creating an type-level value for a kind can get really tedious and boilerplatey. Either reuse ones that exist or publish your own for the benefit of the entire community.

## Other Learning Sources

Consider purchasing the `Thinking with Types` book mentioned in `ROOT_FOLDER/Syntax/Type-Level Programming Syntax/ReadMe.md`

## Compilation Instructions

```bash
spago run -m TLP.SymbolExample
spago run -m TLP.RowExample
```
