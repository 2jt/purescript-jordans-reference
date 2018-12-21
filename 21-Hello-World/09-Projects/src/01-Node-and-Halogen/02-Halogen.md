# Halogen

Since I'm already somewhat familiar with it, I decided to implement the web-based user interface using Halogen.

## Halogen Examples' Compilation Problems

**WARNING!** As of this writing, Halogen's `master` branch is currently in development and their `examples` directory within that branch has not yet been updated. If you try to compile the examples with the `master` branch checked out, it will fail to compile. Instead, check out their `v4.0.0` tag and try the examples there.

## Halogen Guide

Halogen has a lot of generic/polymorphic types. So, read through my "bottom up" approach first, which introduces these types one at a time. Then, read through the "top-down" approach alongside of the flowchart:
- [My "bottom-up" explanation](https://github.com/slamdata/purescript-halogen/tree/1e13c931f242f0ea72a92ed1b560110833ab2f1c/docs/v2). I stopped at a certain point because of the currently not-well-documented API changes they are making in the upcoming `5.0.0` release.
- [Their "top-down" approach](https://github.com/slamdata/purescript-halogen/tree/v4.0.0/docs).
- [The flowchart I made](https://github.com/slamdata/purescript-halogen/issues/528#issuecomment-431885061) that helps one see how the code actually works. While this flowchart is highly accurate, the issue in which it is contained explains more context on the parts where I misunderstood something.
