#!/bin/bash
set -e
set -u
set -o pipefail


###############################################################################
# 18 / 1 / 2017
# Script to setup R package for use in the current project
#
# Assumes that all RH-generated R function scripts have been put in
#   subdirectories of ./lib/global_rfuncs or ./lib/local_rfuncs
#   and that if the R/ subdirectory of both of these dirs is empty, then
#   this script aborts, since there is no R package to build if there is no
#   source code for that package
#
# This script should be called by ./scripts/setup.sh
#   - the global variable IS_R_REQUIRED should exist and should be 1 for this
#     script to build an R package
#   - TODO - ? considerations for building python package structures
#
# Checks that ./lib/Makefile and ./lib/setup.DESCRIPTION.R exist and assumes
#   they take arguments 'jobname' and 'r_includes'
#
# If the file does not already exist, this script will make the empty file
#   ./lib/conf/include_these_rpackages.txt
#   but if it already exists then the file is used as a list of imported
#   packages
#   - if this file is empty, it is assumed that the job-specific package does
#     not need to import any packages
#
###############################################################################

die_and_moan()
{
  echo -e "$1" >&2
  exit 1
}

###############################################################################

# define function for setting up the R package:
function build_r_package {
  JNAME="${1}"
  PNAME="${2}"
  R_INC="${3}"
  # Check that r_includes is an absolute path to an existing file
  if [[ "${R_INC:0:1}" != "/" ]] && \
     [[ "${R_INC:0:2}" != "~" ]] && \
     [[ "${R_INC:0:2}" != "~/" ]];
  then
    die_and_moan \
    "${0}: Path to R_INCLUDES should be absolute in setup_libs.sh"
  fi

  # Check that ./lib/Makefile exists
  # - Any other requirements of ./lib/Makefile should be checked by itself
  if [[ ! -f ./lib/Makefile ]];
  then
    die_and_moan \
    "${0}: Makefile for building the libraries/packages for this job is \
    \n ... missing from ./lib"
  fi

  cd ./lib
  make pkgname="${PNAME}" \
       r_includes="${R_INC}"
  cd ..
}

###############################################################################

# define function for installing the R package

function install_r_package {
  # # install the R package if it is newer than the installed R package
  # install_r_package "${PKGNAME}" "${PKG_TAR}" "${R_LIB_DIR}"

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

  if [[ ! -d "${R_LIB_DIR}/${PKGNAME}" ]] ||
     [[ "${R_LIB_DIR}/${PKGNAME}" -ot "${PKG_LOCAL_TAR}" ]];
  then
    echo "*** Installing into ${R_LIB_DIR} ***" >&2
    Rscript -e "pkg = commandArgs(trailingOnly = TRUE)" \
            -e "install.packages(pkg, repos = NULL, type = 'source')" \
            ${PKG_LOCAL_TAR}
  fi

}

###############################################################################

# This script should have been called from ./scripts/setup.sh
# Therefore, Check that JOBNAME, PKGNAME and IS_R_REQUIRED are all defined
# Check that the conda environment for the current job is activated
# Determine the R-LIBS directory for the current conda environment

if [[ -z "${JOBNAME}" ]] || \
   [[ -z "${PKGNAME}" ]] || \
   [[ -z "${IS_R_REQUIRED}" ]] || \
   [[ -z "${IS_R_PKG_REQUIRED}" ]] || \
   [[ -z "${CONDA_PREFIX}" ]];
then
  die_and_moan \
  "${0}: JOBNAME, PKGNAME, IS_R_REQUIRED, IS_R_PKG_REQUIRED and CONDA_PREFIX \
  \n ... should be defined, CONDA_PREFIX is usually set up by the anaconda \
  \n ... environment, setup_libs.R should have been called from setup.sh."
fi

###############################################################################

# Call the function for setting up the R package if:
#   - IS_R_REQUIRED;
#   - IS_R_PKG_REQUIRED
#   - and there are some .R scripts in ./lib/local_rfuncs/R or
#   ./lib/global_rfuncs/R;
#   - and a Makefile is found in ./lib (checked in build_r_package)
#   - and a "setup.DESCRIPTION.R" file is found in ./lib (checked in Makefile)
#   - and the global vars JOBNAME and PKGNAME are defined (checked above)

# Call the function for installing the R package if additionally:
#   - the built R-package has never been installed
#   - or the tar.gz for the built R-package is newer than the installed version

if [[ ${IS_R_REQUIRED} -ne 0 ]] && [[ ${IS_R_PKG_REQUIRED} -ne 0 ]];
then
  # Set default val for the file that specifies which packages to include in
  # the job-specific pacakge
  if [[ -z "${R_INCLUDES_FILE}" ]];
  then
    R_INCLUDES_FILE="${PWD}/lib/conf/include_into_rpackage.txt"
    export R_INCLUDES_FILE
  fi

  # Determine if there are any function scripts in lib/global_rfuncs/R/*.R or
  #   lib/local_rfuncs/R/*.R for packaging up
  #   - The global files should have been copied in by setup_dirs.sh based on
  #     ./.setup_config/copy_these_files.txt (or cloned from bitbucket)
  R_FUNCTION_FILES=(`find ./lib/*_rfuncs/R/ -type f -name "*.R"`)
  {% raw -%}
  NUM_R_FILES=${#R_FUNCTION_FILES[@]}
  {%- endraw %}

  # Build/install the package if there are any files to package up and the
  # scripts required for packaging exist
  #   -
  # All built packages should be placed into ./lib/built_packages/
  # and are installed from this directory
  if [[ ${NUM_R_FILES} > 0 ]];
  then
    build_r_package "${JOBNAME}" "${PKGNAME}" "${R_INCLUDES_FILE}"
  fi
fi

# Where I've copied one of my own packages into the source code for a package,
#   build that package and put the package-archive into ./lib/built_packages
#
if [[ -d "./lib/copied_packages" ]] || [[ -d "./lib/cloned_packages" ]]; then
  for PKG_PATH in \
    $(find "lib/cloned_packages" -maxdepth 1 -mindepth 1 -type d) \
    $(find "lib/copied_packages" -maxdepth 1 -mindepth 1 -type d);
  do
    Rscript \
      ./scripts/helpers_for_setup/package_builder.R \
      "${PKG_PATH}" \
      "./lib/built_packages"
  done
fi

###############################################################################

# Install any of the packages that were copied into the current R environment
#
if [[ -d "./lib/built_packages" ]]; then
  for PKG_TAR in \
    $(find "lib/built_packages" -name "*.tar.gz");
  do
    # The R library directory for the current conda environment is:
    R_LIB_DIR="${CONDA_PREFIX}/lib/R/library"

    # The package archives are like
    #   ./lib/built_packages/pkgname_0.1.2.333.tar.gz
    PKGNAME=$(basename ${PKG_TAR} | sed -e "s/_*[0-9.]\+tar\.gz//")

    # Install the R package if it is newer than the installed R package
    install_r_package "${PKGNAME}" "${PKG_TAR}" "${R_LIB_DIR}"
  done
fi

###############################################################################
# ? skeleton code for building python package?
# <TODO>

###############################################################################
