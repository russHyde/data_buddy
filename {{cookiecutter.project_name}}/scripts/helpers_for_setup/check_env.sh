#!/bin/bash
set -e
set -o pipefail

###############################################################################
# 5 / 12/ 2016
# Requires that (CONDA_DIR and CONDA_ENV_DIR)  or (CONDA_DIR and JOBNAME) are
#   defined and exported
# Requires that IS_R_REQUIRED is defined
# <TODO>: IS_JUPYTER_REQUIRED
#
# If CONDA_ENV_DIR is not defined, it is assumed to be
#   ${CONDA_DIR}/envs/${JOBNAME}
#
# Checks if the active python dist is called from ${CONDA_ENV_DIR}/python
#
# If IS_R_REQUIRED is non-zero, checks that the active Rscript is called from
#   the CONDA_ENV_DIR as well

###############################################################################

die_and_moan()
{
  echo -e "$1" >&2
  exit 1
}

###############################################################################

# Name of the conda environment that should be activated for this work-job:
REQD_CONDA_ENV="$1"

if [[ -z "${REQD_CONDA_ENV}" ]]; then
  die_and_moan \
  "${0}: call `./path/to/check_env.sh NAME_OF_EXPECTED_CONDA_ENV` next time"
  fi

if [[ -z "${CONDA_PREFIX}" ]] || \
   [[ -z "${CONDA_DEFAULT_ENV}" ]]; then
  die_and_moan \
  "${0}: CONDA_PREFIX or CONDA_DEFAULT are undefined \
  \n -- perhaps you haven't activated the work-package's conda env?"
  fi

if [[ "${REQD_CONDA_ENV}" != "${CONDA_DEFAULT_ENV}" ]]; then
  die_and_moan \
  "${0}: REQD_CONDA_ENV ${REQD_CONDA_ENV} is not activated"
  fi

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
