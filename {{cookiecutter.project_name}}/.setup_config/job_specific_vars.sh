#!/bin/bash -e

###############################################################################
# User-specified variables for use in the `{{cookiecutter.project_name}}`
# project

###############################################################################
# `JOBNAME` and `IS_R_REQUIRED` must be defined for each new project
#
# `IS_R_REQUIRED=1` if R is to be used in addition to pythono within the current
# project
# `IS_R_PKG_REQUIRED=1` is required if an R package is to be made
# `IS_JUPYTER_R_REQUIRED=1` is required if an R kernel is to be made

export JOBNAME="{{cookiecutter.project_name}}"
export IS_R_REQUIRED={{cookiecutter.is_r_required}}
export IS_R_PKG_REQUIRED={{cookiecutter.is_r_pkg_required}}
export IS_JUPYTER_R_REQUIRED={{cookiecutter.is_jupyter_r_kernel_required}}

###############################################################################
# PKGNAME is the name of the job-specific R package
# - Note that the R-package <PKGNAME> will only be built/installed if the user
#   adds some files to the subdirectories ./lib/local_rfuncs/R or
#   ./lib/global_rfuncs
# - The R_INCLUDES_FILE defines which external R packages are 'include'd by the
#   job-specific package

if [[ ! -z "${IS_R_PKG_REQUIRED}" ]] && [[ ${IS_R_PKG_REQUIRED} -ne 0 ]];
then
  export PKGNAME="{{cookiecutter.r_pkg_name}}"
  export R_INCLUDES_FILE="${PWD}/lib/conf/include_into_rpackage.txt"
fi

# ENVNAME is the name of the job-specific conda environment
export ENVNAME="{{cookiecutter.conda_env}}"

###############################################################################
if [[ ! -z "${IS_JUPYTER_R_REQUIRED}" ]] && [[ ${IS_JUPYTER_R_REQUIRED} -ne 0 ]];
then
  export R_KERNEL="conda-env-${ENVNAME}-r"
fi
