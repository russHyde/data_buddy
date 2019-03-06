#!/bin/bash
set -e
set -o pipefail

###############################################################################
# If IS_R_REQUIRED is non-zero, checks that the active Rscript is called from
#   the current conda env

###############################################################################

die_and_moan()
{
  echo -e "$1" >&2
  exit 1
}

###############################################################################

# Name of the conda environment that should be activated for this work-job:
REQD_CONDA_ENV="$1"

###############################################################################
# Check that the conda environment for the current workjob is activated
#   and that a valid python (and R, if required) exists
EXPECTED_PYTHON="${CONDA_PREFIX}/bin/python"
PYTHON=`which python`
if [[ "${PYTHON}" != "${EXPECTED_PYTHON}" ]]; then
  die_and_moan \
  "${0}: Python should be within the ${REQD_CONDA_ENV} environment"
  fi

###############################################################################
# If the user has set IS_R_REQUIRED in the env, check that Rscript is called
#   within the required conda environment
if [[ "${IS_R_REQUIRED}" != 0 ]]; then
  EXPECTED_RSCRIPT="${CONDA_PREFIX}/bin/Rscript"
  RSCRIPT=`which Rscript`

  if [[ "${RSCRIPT}" != "${EXPECTED_RSCRIPT}" ]]; then
    die_and_moan \
    "${0}: The 'Rscript' program is defined in an env other than ...\n
     '${REQD_CONDA_ENV}'; perhaps you should 'conda install r-base r-irkernel'"
    fi

  if [[ ! -f "${RSCRIPT}" ]];
  then
    die_and_moan \
    "${0}: No file for 'Rscript' in conda environment ${REQD_CONDA_ENV}"
  fi
fi

###############################################################################
