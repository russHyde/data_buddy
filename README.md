# data_buddy

This repository contains some scripts I use when running a data-analysis
project.

My data analysis projects contain

- details of a project-specific conda environment that should be created and
  activated before running anything

- some non-conda packages and scripts that I use in multiple projects. These
  are either

    - copied in from local directories / files (in which case the current
      project should keep them under version control); or

    - (preferably) cloned from a github or bitbucket repository. In the latter
      case, an explicit package version is included by specifying a git-commit
SHA and branch (in which case the current project does not keep the included
package under version control).

- packages & scripts that are developed specifically for the current project

- a `Snakefile` for controlling the running of the project scripts

- links to data

- subjobs (which are nested copies of the project structure, but which are
  version-controlled and environment-defined within the main project)

----

Since `data_buddy` will progressively change, it should be copied into any new
project (for the moment at least).

All config files for use in `data_buddy` should be stored in
`./.sidekick/setup_config`
