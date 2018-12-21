# Projects

This folder's purposes are
- to solidify one's understanding for how to write FP programs according to modern FP architecture principles.
    - Explain the throught-process behind designing some program by starting with the properties one wants to employ. This will include diagrams and other explanations.
    - Compare the various ways one can structure an FP program and analyze their pros/cons and other tradeoffs
        - "standard" ReaderT approach
        - "layered compilers" Free/Run approach
        - "layered compilers" ReaderT approach
    - Explain and show how to test and benchmark our code
- to introduce the reader to a few commonly-used libraries in the "real world."
    - We'll introduce/overview the libraries we'll use in later projects before using them in those projects.
- to help the reader determine which approach with which they feel most comfortable (there is no "the one and only way" to doing this)

Note: each 'project' folder in the `src` folder has a corresponding folder in `test` folder. When reading through a project's files, read through its `src` folder's content before its `test` folder's content.

## Libraries Overviewed

Below is the current list of libraries we introduce and further explain here. This list may grow over time.
- `Node.ReadLine` for console-based programs
- `Halogen` for web-based programs
- `Aff` for using asynchronous effects

## Projects

- (Easy) "Guess the Random Number" game.

## Compilation Instructions

Each folder will specify the `pulp` command to run to build/run the program. Because of the multi-project nature of this folder, the `pulp` command must be executed in `Hello World/Projects/`, not in each project's folder.
To run a web-based program, follow the folder's build instructions and then open the `dist/<project-name>/<FP structure approach>/index.html` file
