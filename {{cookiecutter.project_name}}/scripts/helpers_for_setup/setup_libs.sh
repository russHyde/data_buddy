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

# Define function for installing the R package

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

  # If PKG_R_DIR does not exist, the package has not been installed yet
  #  ==> therefore install it

  # Get timestamp for PKG_R_DIR (the version installed in conda-R) and for
  #   PKG_LOCAL_TAR (the recently built version of the package).
  # If PKG_LOCAL_TAR is more recent that PKG_R_DIR, then the installed version
  #   of the package predates the available version
  # ==> therefore install it

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

# Call the function for setting up the R package if:
#   - IS_R_REQUIRED;
#   - IS_R_PKG_REQUIRED
#   - and there are some .R scripts in ${LIB_DIR}/local_rfuncs/R or
#   ${LIB_DIR}/global_rfuncs/R;
#   - and a Makefile is found in ${LIB_DIR} (checked in build_r_package)
#   - and a "setup.DESCRIPTION.R" file is found in ${LIB_DIR} (checked in
#   Makefile)
#   - and the global vars JOBNAME and PKGNAME are defined (checked above)

# Call the function for installing the R package if additionally:
#   - the built R-package has never been installed
#   - or the tar.gz for the built R-package is newer than the installed version

if [[ ${IS_R_REQUIRED} -ne 0 ]] && [[ ${IS_R_PKG_REQUIRED} -ne 0 ]];
then
  if [[ -z "${PKGNAME}" ]];
  then
    die_and_moan \
    "${0}: PKGNAME should be defined, since IS_R_PKG_REQUIRED is true for this \
    \n ... project"
  fi

  # Set default val for the file that specifies which packages to include in
  # the job-specific pacakge
  if [[ -z "${R_INCLUDES_FILE}" ]];
  then
    R_INCLUDES_FILE="${LIB_DIR}/conf/include_into_rpackage.txt"
    export R_INCLUDES_FILE
  fi

  # Determine if there are any function scripts in lib/global_rfuncs/R/*.R or
  #   lib/local_rfuncs/R/*.R for packaging up
  #   - The global files should have been copied in by setup_dirs.sh based on
  #     ./.sidekick/setup/copy_these_files.txt (or cloned from bitbucket)
  R_FUNCTION_FILES=(`find "${LIB_DIR}/"*_rfuncs/R/ -type f -name "*.R"`)

  {% raw -%}
  NUM_R_FILES=${#R_FUNCTION_FILES[@]}
  {%- endraw %}

  # Build/install the package if there are any files to package up and the
  # scripts required for packaging exist
  #   -
  # All built packages should be placed into ${LIB_DIR}/built_packages/
  # and are installed from this directory
  if [[ ${NUM_R_FILES} > 0 ]];
  then
    build_r_package \
      "${JOBNAME}" \
      "${PKGNAME}" \
      "${R_INCLUDES_FILE}" \
      "${LIB_DIR}"
  fi
fi

# Where I've copied one of my own packages into the source code for a package,
#   build that package and put the package-archive into
#   ${LIB_DIR}/built_packages
#
if [[ -d "${LIB_DIR}/cloned_packages" ]] || \
   [[ -d "${LIB_DIR}/copied_packages" ]];
then
  for PKG_PATH in \
    $(find "${LIB_DIR}/cloned_packages" -maxdepth 1 -mindepth 1 -type d) \
    $(find "${LIB_DIR}/copied_packages" -maxdepth 1 -mindepth 1 -type d);
  do

    if [[ ! -f "${R_BUILDER_SCRIPT}" ]]; then
      die_and_moan \
        "${0}: the R-package building script ${R_BUILDER_SCRIPT} is missing"
    fi

    mkdir -p "${LIB_DIR}/built_packages"

    Rscript \
      "${R_BUILDER_SCRIPT}" \
      "${PKG_PATH}" \
      "${LIB_DIR}/built_packages"
  done
fi

###############################################################################

# Install any of the packages that were copied into the current R environment
#
if [[ -d "${LIB_DIR}/built_packages" ]];
then
  for PKG_TAR in \
    $(find "${LIB_DIR}/built_packages" -name "*.tar.gz");
  do
    # The package archives are like
    #   ${LIB_DIR}/built_packages/pkgname_0.1.2.333.tar.gz
    PKG_NAME=$(basename ${PKG_TAR} | sed -e "s/_*[0-9.]\+tar\.gz//")

    # Install the R package if it is newer than the installed R package
    install_r_package "${PKG_NAME}" "${PKG_TAR}" "${CONDA_R_LIB}"
  done
fi

###############################################################################
