#!/bin/bash
set -e
set -u
set -o pipefail


###############################################################################
# Script to setup R package for use in the current project
#
# This script should be called by ./scripts/setup.sh
#   - the global variable IS_R_REQUIRED should exist and should be 1 for this
#     script to build an R package
#
###############################################################################

die_and_moan()
{
  echo -e "$1" >&2
  exit 1
}

###############################################################################

# Function to define a skeleton for a local R package

function define_package_skeleton {

  PKGNAME="${1}"
  PARENT_DIR="${2}"

  if [[ -z "${PKGNAME}" ]];
  then
    die_and_moan \
    "${0}: PKGNAME should be defined when defining the package-skeleton for \
    \n ... a subjob"
  fi

  if [[ ! -d "${PARENT_DIR}" ]];
  then
    die_and_moan \
      "${0}: PARENT_DIR should be a directory in 'define_package_skeleton'. \
      \n ... PARENT_DIR='${PARENT_DIR}'"
  fi

  # If no local package exists by this name (<PKGNAME>), then initialise one
  # It's source code will be stored in ./lib/local/<PKGNAME>

  if [[ ! -d "${PARENT_DIR}/${PKGNAME}"  ]];
  then
    Rscript \
      -e "args <- commandArgs(trailingOnly = TRUE);" \
      -e ".id <- function(x) {x};" \
      -e "utils::package.skeleton(name = args[1], path = args[2], list = '.id')" \
      "${PKGNAME}" "${PARENT_DIR}"
  fi
}

###############################################################################

# Function for installing an R package

function install_r_package {
  # To call this function:
  # install_r_package "${PKGNAME}" "${PKG_TAR}" "${R_LIB_DIR}"

  # Every R package installed here should have:
  # - a package archive (eg, lib/built_packages/<some_pkg>_0.1.2.3.tar.gz)
  #
  # ... and should be installed into a subdirectory of `${R_LIB_DIR}` (eg,
  # ~/miniconda/envs/<current_env>/lib/R/libs/<some_pkg>/)

  # An R package should be installed from a package archive if:
  # - the package is not currently installed (ie, it is absent from the R
  # library for the current environment)
  # - the archive is newer than the currently-installed version of the package
  # (where there are multiple archives for the same package in
  # lib/built_packages, this should also ensure that only the most recently
  # built archive will be installed)
  # - the dependencies for the package are installed in the current environment
  # (an error should be thrown if any dependencies are missing)

  PKGNAME="${1}"
  PKG_LOCAL_TAR="${2}"
  R_LIB_DIR="${3}"

  # Check that the given R libraries directory is valid:
  if [[ ! -d "${R_LIB_DIR}" ]];
  then
    die_and_moan \
    "${0}: R_LIB_DIR should be a defined directory in install_r_packages: \
    ... Current value is ${R_LIB_DIR}"
  fi

  # If the package does not have a subdirectory in ${R_LIB_DIR}, then it has
  # not been installed yet
  #  ==> therefore install it

  # Get timestamp for the pkg version installed in conda-R and for
  #   PKG_LOCAL_TAR (the recently built version of the package).
  # If PKG_LOCAL_TAR is more recent than the installed version, then the
  # package has been updated
  #  ==> therefore reinstall it

  # By using `R CMD INSTALL` instead of `Rscript -e 'install.packages(...)'` we
  # ensure that if a package fails to install (eg, due to missing dependencies)
  # then this setup script should die

  if [[ ! -d "${R_LIB_DIR}/${PKGNAME}" ]] ||
     [[ "${R_LIB_DIR}/${PKGNAME}" -ot "${PKG_LOCAL_TAR}" ]];
  then
    echo "*** Installing into ${R_LIB_DIR} ***" >&2
    R CMD INSTALL -l "${R_LIB_DIR}" ${PKG_LOCAL_TAR}
  fi

}

###############################################################################

# For each package in a source directory (typically lib/local or lib/remote),
# this function will build a tar.gz file from that R package and then install
# the package from that tar file into the current conda env.

function build_and_install_each_package {
  # SRC_DIR
  # BUILD_DIR
  # CONDA_LIB
  # BUILDER_SCRIPT

  SRC_DIR="${1}"
  BUILD_DIR="${2}"
  CONDA_LIB="${3}"
  BUILDER_SCRIPT="${4}"

  if [[ ! -d "${BUILD_DIR}" ]]; then mkdir -p "${BUILD_DIR}"; fi

  if [[ ! -f "${BUILDER_SCRIPT}" ]]; then
    die_and_moan \
      "${0}: the R-package building script ${BUILDER_SCRIPT} is missing"
  fi

  for PKG_PATH in \
    $(find "${SRC_DIR}" -maxdepth 1 -mindepth 1 -type d);
  do
    PKG_NAME=$(basename "${PKG_PATH}")

    # Build a tar.gz archive for the current package
    Rscript "${BUILDER_SCRIPT}" "${PKG_PATH}" "${BUILD_DIR}"

    # Then install the latest .tar.gz corresponding to the current package
    # (Note that this is a bit of a hack, and may lead to multiple .tar.gz
    # getting installed sequentially for the same package)
    for PKG_TAR in \
      $(find "${LIB_DIR}/built" -name "${PKG_NAME}_*.tar.gz")
    do
      # Install the R package if it is newer than the installed R package
      install_r_package "${PKG_NAME}" "${PKG_TAR}" "${CONDA_LIB}"
    done
  done
}

###############################################################################

# -- script -- #

# This script builds and installs any R packages that are stored in
# `${LIB_DIR}/remote` or `${LIB_DIR}/local`. "*.tar.gz" files for each package
# are stored in `${LIB_DIR}/built` and then installed into the CONDA
# environment.
#
# Packages in `./lib/remote` are built/installed first and building/installing
# occurs sequentially for each package (rather than building all packages and
# then installing them all)
#
# Where the user states to build a project-specific package,
# (with IS_R_PKG_REQUIRED=1), but such a package does not yet exist, this
# script initialises an empty package in `${LIB_DIR}/local/<PKGNAME>`. The user
# should modify this package skeleton as they would for any other R package.

###############################################################################

# This script should have been called from ./scripts/setup.sh
# Therefore, Check that JOBNAME, PKGNAME and IS_R_REQUIRED are all defined
# Check that the conda environment for the current job is activated
# Determine the R-LIBS directory for the current conda environment

if [[ -z "${JOBNAME}" ]] || \
   [[ -z "${IS_R_REQUIRED}" ]] || \
   [[ -z "${IS_R_PKG_REQUIRED}" ]] || \
   [[ -z "${CONDA_PREFIX}" ]] || \
   [[ -z "${LIB_DIR}" ]];
then
  die_and_moan \
  "${0}: JOBNAME, LIB_DIR, IS_R_REQUIRED, IS_R_PKG_REQUIRED and CONDA_PREFIX \
  \n ... should be defined. CONDA_PREFIX is usually set up by the anaconda \
  \n ...  environment. `setup_libs.R` should have been called from `setup.sh`."
fi

# This script is used to build R packages from source
R_BUILDER_SCRIPT="${SETUP_HELPERS_DIR}/package_builder.R"

# The R library directory for the current conda environment is:
CONDA_R_LIB="${CONDA_PREFIX}/lib/R/library"

###############################################################################

# If the user wants to make a project-specific package (and one doesn't
# currently exist), put a skeleton package for holding the source code into
# ./lib/local/<PKGNAME>
#
# The user should modify this skeleton if they want to add extra code and then
# rerun `./sidekick setup` to build / install it.

if [[ ${IS_R_REQUIRED} -ne 0 ]] && [[ ${IS_R_PKG_REQUIRED} -ne 0 ]];
then
  define_package_skeleton "${PKGNAME}" "${LIB_DIR}/local"
fi

# Build & Install packages (remotes first)

build_and_install_each_package \
  "${LIB_DIR}/remote" \
  "${LIB_DIR}/built" "${CONDA_R_LIB}" ${R_BUILDER_SCRIPT}

build_and_install_each_package \
  "${LIB_DIR}/local" \
  "${LIB_DIR}/built" "${CONDA_R_LIB}" ${R_BUILDER_SCRIPT}

###############################################################################
