# Project `{{cookiecutter.project_name}}`

## Overview

<!-- User to fill in the details -->

## Dataset details

<!-- User to fill in the details -->

## To run the project

Change in to the project directory.

If necessary, create the conda environment for the main project:

`conda create --name {{cookiecutter.conda_env}} --file envs/requirements.txt`

Activate the project's environment

`conda activate {{cookiecutter.conda_env}}`

Set up the filepaths and project-specific packages:

`./sidekick setup`

[Optional] If you have set up a set of validation tests for the input data:

`./sidekick validate --yaml <input_validation_tests>.yaml`

Run the snakemake file:

`snakemake --use-conda <flags>`

The flags recommended for the current project are as follows:

<!-- User to update the flags, based on project requirements -->

- No flags recommended

[Optional] If you have set up a set of validation tests for the results file
(recommended within iterative projects):

`./sidekick validate --yaml <results_validation_tests>.yaml`
