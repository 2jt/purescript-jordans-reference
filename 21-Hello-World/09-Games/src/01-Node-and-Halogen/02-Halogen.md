# Halogen

Since I'm already somewhat familiar with it, I decided to implement the web-based user interface using Halogen. Halogen has a lot of generic/polymorphic types. So, read through my "bottom up" approach first, which introduces these types one at a time. Then, read through the "top-down" approach alongside of the flowchart:
- [My "bottom-up" explanation](https://github.com/slamdata/purescript-halogen/tree/1e13c931f242f0ea72a92ed1b560110833ab2f1c/docs/v2). I stopped at a certain point because of the currently not-well-documented API changes they are making in the upcoming `5.0.0` release.
- [Their "top-down" approach](https://github.com/slamdata/purescript-halogen/tree/v4.0.0/docs).
- [The flowchart I made](https://github.com/slamdata/purescript-halogen/issues/528#issuecomment-400071113) that helps one see how the code actually works. While this flowchart is highly accurate, the issue in which it is contained explains more context on the parts where I misunderstood something.

## Halogen Warning

**WARNING!** As of this writing, Halogen's `master` branch is currently in development and their `examples` directory within that branch has not yet been updated. If you try to compile the examples with the `master` branch checked out, it will fail to compile. Instead, check out their `v4.0.0` tag and try the examples there.

## Code Warning

The browser-based UI you will see in both the Free- and Run-based code will look utterly horrible! This is intentional for two reasons:
1. The pattern to follow is easier to see without CSS and additional events cluttering up the code base
2. While I know some HTML/CSS, my learning focus has been on Purescript. I currently don't know best practices when it comes to HTML and CSS, but I will learn those things after I get more familiar with Purescript.
