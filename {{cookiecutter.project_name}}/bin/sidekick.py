#!/usr/bin/env python3

"""
This script calls the code for various aspects of the current project:

- `sidekick setup ...` : set-up the file-structure / packages for the current
  project.

- `sidekick validate --yaml ...` : check that results files or input data files
  are consistent with the expectations (eg, they haven't been corrupted during
  storage / transfer or altered by changes to the analysis code).
"""

import argparse
import os
import subprocess


def setup(args):
    """
    Run the setup script for this project.
    This:
    - Checks the environment
    - Defines the file structure
    - Builds and installs any required packages
    - Then does this recursively for any subprojects
    """
    subprocess.run(["./scripts/setup.sh"])


def validate(args):
    """
    Run the file-validation script for this project.
    This is typically used to:
    - Ensure that data files are uncorrupted
    - Check that restructuring the project code does not affect the results
      files
    """
    validation_script = os.path.join(
        "bin", "buddy", "buddy", "validate_file_contents.py"
    )
    subprocess.run(["python", validation_script, args.yaml])


# ---- parsers


def add_setup_subparser(subparsers):
    """
    Add a parser for `./sidekick setup` arguments.
    """

    setup_parser = subparsers.add_parser("setup")
    setup_parser.set_defaults(func=setup)


def add_validation_subparser(subparsers):
    """
    Add a parser for `./sidekick validate` arguments.
    """
    validation_parser = subparsers.add_parser("validate")
    validation_parser.set_defaults(func=validate)
    validation_parser.add_argument("--yaml", type=str, nargs=1, required=True)


def define_parser():
    """
    Parser for all `sidekick` arguments
    """
    parser = argparse.ArgumentParser(prog="sidekick")

    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True

    add_setup_subparser(subparsers)
    add_validation_subparser(subparsers)

    return parser


# ---- runner


def main():
    """
    Run the program
    """
    parser = define_parser()
    args = parser.parse_args()

    args.func(args)


# ---- script

if __name__ == "__main__":
    main()
