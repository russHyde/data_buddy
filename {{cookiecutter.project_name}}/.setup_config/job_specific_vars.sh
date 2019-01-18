#!/bin/bash -e

###############################################################################
# 24/1/2017
# User-specified variables for use in the drug_markers project

###############################################################################
# JOBNAME and IS_R_REQUIRED must be defined for each new project
#
# IS_R_REQUIRED=1 is required if an R kernel is to be made or R is to be used
# IS_R_PKG_REQUIRED=1 is additionally required if an R package is to be made
export JOBNAME="{{cookiecutter.project_name}}"
export IS_R_REQUIRED={{cookiecutter.is_r_required}}
export IS_R_PKG_REQUIRED={{cookiecutter.is_r_pkg_required}}
export IS_JUPYTER_R_REQUIRED={{cookiecutter.is_jupyter_r_kernel_required}}

# Nonessential variables:
#
# - Define which external R packages are 'include'd by the job-specific package
export R_INCLUDES_FILE="${PWD}/lib/conf/include_into_rpackage.txt"

###############################################################################
# PKGNAME and ENVNAME can be overridden by the user
# - Note that the R-package <PKGNAME> will only be built/installed if the user
#   adds some files to the subdirectories ./lib/local_rfuncs/R or
#   ./lib/global_rfuncs
#
export PKGNAME=`echo "${JOBNAME}" | sed s/_/./g`
export ENVNAME="{{cookiecutter.conda_env}}"

###############################################################################
if [[ ! -z "${IS_JUPYTER_R_REQUIRED}" ]] && [[ ${IS_JUPYTER_R_REQUIRED} -ne 0 ]];
then
  export R_KERNEL="conda-env-${ENVNAME}-r"
fi
