# Other Important Info

[Purescript By Example](https://leanpub.com/purescript/read#) is a book that teaches Purescript. Unfortunately, it is now outdated because it covers Purescript `0.11.7` and not `0.12.x`, which introduced a lot of breaking changes. However, it's still a useful learning resource.

If you decide to read the book, here are things to be aware of:
- be wary of any references to these [deprecated packages](https://github.com/purescript-deprecated)
- **Refer to [`dwhitney`'s fork of the book's code](https://github.com/dwhitney/purescript-book/tree/0.12)**, which is currently being updating to use `0.12.x`.
- Refer to the ReadMe in `Hello-World/Hello-World-and-Effects/Effect-Eff-and-Aff.md` to understand how to translate the no-longer-used `Eff` type to `Effect` type.

## Differences From Haskell

If you're coming to PureScript with a Haskell background, be sure to consult the following resources:
- [Introduction to Purescript for Haskell Developers](http://code.adriansieber.com/adrian/adriansieber-com/src/branch/master/posts/_2018-11-01_introduction_to_purescript_for_haskell_developers/main.pdf) (pdf)
- [The Purescript Documentation Repo's "Differences from Haskell" page](https://github.com/purescript/documentation/blob/master/language/Differences-from-Haskell.md)

## Documenation

- Anytime you need to look up the documentation for a package, use [Pursuit](http://pursuit.purescript.org/). Be aware that some of the deprecated packages mentioned above are still posted there.
- Read [Pursuit's Search Help page](https://pursuit.purescript.org/help/users#searching)
- Some libraries have not been updated to `0.12.x` (released on `2018/05/21`) and are still on the `0.11.7` release. Some still work; others won't. In this work, we will insure that you do not use any such libraries, but be aware of that if you browse the docs on your own.
- Lastly, Bower, the dependency manager used to publish docs to Pursuit, [is currently causing an issue](https://github.com/purescript-contrib/pulp/issues/351) that has prevented some libraries (e.g. Halogen) from uploading their latest versions' documentation. In these cases, we will forewarn you when you will need to read through the source code of a library rather than the Pursuit docs.
