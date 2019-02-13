#!/bin/bash
set -e
set -u
set -o pipefail

###############################################################################
#
# Script to
#   i) set up the directory structure of the current project,
#   ii) check the existence of any required external directories
#   iii) make links from the current project to any specified external files
#   iv) make copies of any specified external files in the current project
#   v) import any github/bitbucket repositories into the current project
#
# User must define CHECK_DIRS_FILE,
#                  MAKE_DIRS_FILE,
#                  MAKE_LINKS_FILE,
#                  MAKE_FILE_COPIES_FILE,
#                  MAKE_DIR_COPIES_FILE,
#                  TOUCH_FILES_FILE,
#                  REPO_CLONING_CONFIG (.yaml file)
#
# If these filenames aren't defined (or are not valid files), the script will
#   die and the corresponding files/dirs/links will not be made/checked
#
# Note that any link/file that is present in MAKE*_FILE should be checked for
#   existence and that any comment lines / blank lines should be dropped
#
###############################################################################

expand_tilde()
{
  echo "$1" | perl -lne 'BEGIN{$H=$ENV{"HOME"}}; s/~/$H/; print'
}

die_and_moan()
{
  echo -e "$1" >&2
  exit 1
}

###############################################################################
if [[ -z "${CHECK_DIRS_FILE}" ]] || [[ ! -f "${CHECK_DIRS_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export CHECK_DIRS_FILE, a file(name) \
  \n ... containing directories that must exist before running the workflow"
fi

if [[ -z "${MAKE_DIRS_FILE}" ]] || [[ ! -f "${MAKE_DIRS_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export MAKE_DIRS_FILE, a file(name) \
  \n ... containing directory locations that should exist after running \
  \n ... 'setup_dirs.sh'"
fi

if [[ -z "${MAKE_LINKS_FILE}" ]] || [[ ! -f "${MAKE_LINKS_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export MAKE_LINKS_FILE, a file(name) \
  \n ... containing 'target_file\tlink_name' entries for links that should \
  \n ... exist after running 'setup_dirs.sh'"
fi

if [[ -z "${MAKE_FILE_COPIES_FILE}" ]] || \
  [[ ! -f "${MAKE_FILE_COPIES_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export MAKE_FILE_COPIES_FILE, a file(name) \
  \n ... containing 'original_file\tcopy_name' entries for links that should \
  \n ... exist after running 'setup_dirs.sh'"
fi

if [[ -z "${MAKE_DIR_COPIES_FILE}" ]] || \
  [[ ! -f "${MAKE_DIR_COPIES_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export MAKE_DIR_COPIES_FILE, a file(name) \
  \n ... containing 'original_dir\tcopy_name' entries for links that should \
  \n ... exist after running 'setup_dirs.sh'"
fi

if [[ -z "${TOUCH_FILES_FILE}" ]] || [[ ! -f "${TOUCH_FILES_FILE}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export TOUCH_FILES_FILE, a file(name) \
  \n ... containing a list of filenames that should be constructed (even if
  \n ... empty) after running 'setup_dirs.sh'"
fi

if [[ -z "${REPO_CLONING_CONFIG}" ]] || [[ ! -f "${REPO_CLONING_CONFIG}" ]];
then
  die_and_moan \
  "${0}: \
  \n ... User should define/export REPO_CLONING_CONFIG, a yaml file \
  \n ... defining any git repositories (and specific commits therein) that
  \n ... should be cloned and added to the current project"
fi

###############################################################################
# Check the existence of all directorys named in CHECK_DIRS_FILE file
while read -r DNAME;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${DNAME}" ]] || [[ "${DNAME:0:1}" == "#" ]];
  then
    continue
  fi

  # All non-blank lines should refer to a dirname that must exist
  # Interpolate "~"
  if [[ ! -d $(expand_tilde "${DNAME}") ]];
  then
    die_and_moan \
    "${0}: Dirname ${DNAME} is not a valid directory and should exist \
     \n... prior to running setup_dirs.sh"
  fi
done < "${CHECK_DIRS_FILE}"

###############################################################################
# We set up links and their containing directories before setting up all other
# job-specific directories, since many subdirectories of ./data/job will be
# created for outputting alignments etc and ./data/job is a link to ~/job_data.
#
# Similarly, we set up ./data/ext and ./data/int aslinks to ~/ext_data and
# ~/int_data; nonetheless, this job should not be able to make subdirectories
# or files within ~/ext_data and ~/int_data
#
# For links:
# - ignore blank lines
# - die if either targetname or linkname is blank
# - check that the target is a file/dir/link and die if it isn't
# - if the link exists, ensure that it points to the required location
#      (without following all links, that is)
while read -r LINE;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${LINE}" ]] || [[ "${LINE:0:1}" == "#" ]];
  then
    continue
  fi

  # Split the line into target-name and link-name;
  #   - die if either are emptystrings
  #   - check that there are only two entries on the line
  ARY=(${LINE})
  {% raw -%}
  if [[ ${#ARY[@]} -ne 2 ]] || \
     [[ -z "${ARY[0]}" ]]   || \
     [[ -z "${ARY[1]}" ]];
  then
    die_and_moan \
    "${0}: Couldn't parse target-name and link-name from '${LINE}' \
    \n ... make sure there's no spaces in your filenames"
  fi
  {%- endraw %}

  TARGET=$( expand_tilde "${ARY[0]}"  )
  LINKNAME=$( expand_tilde "${ARY[1]}" )

  # Check that the target is an existing file/dir or a link and die if not
  if [[ ! -f "${TARGET}" ]] && \
     [[ ! -d "${TARGET}" ]] && \
     [[ ! -L "${TARGET}" ]];
  then
    die_and_moan \
    "${0}: target ${TARGET} isn't an existing dir/file/link"
  fi

  # The directory in which the link is to be placed should be made if it
  #   doesn't exist
  LINKDIR=$(dirname  "${LINKNAME}")
  if [[ ! -d "${LINKDIR}" ]];
  then
    mkdir -p "${LINKDIR}"
  fi

  # If the link path is already in use, it must be a link and point to the
  # the same path as stored in TARGET
  #
  # Links are made with filepaths that are relative to the dir in which the
  # link is placed. But the target of the link is described in
  # ./.setup_config/make_these_links.txt relative to the working directory for
  # this project.
  #
  # So if ~/abc/def/.setup_config/some.link has target ~/abc/some.target and
  # the working directory is ~/abc/def, then make_these_links.txt will contain
  # the target ../some.target and linkname ./.setup_config/some.link, but after
  # making the link, ./.setup_config will look like "some.link ->
  # ../../some.target".
  #
  # Consequently, when checking whether an existing link points to the intended
  # location, we have to use "readlink -f" to canonicalise both the existing
  # link and the intended target. This allows us to link to a filepath that is
  # also a link.
  #
  if [[ -e "${LINKNAME}" ]] || \
     [[ -L "${LINKNAME}" ]];
  then
    if [[ ! -L "${LINKNAME}" ]];
    then
      die_and_moan \
      "${0}: intended link ${LINKNAME} already exists but is not a link"
    fi
    if [[ "$(readlink -f ${LINKNAME})" != "$(readlink -f ${TARGET})" ]];
    then
      die_and_moan \
      "${0}: intended link ${LINKNAME} already exists and points to a \
      \n different location than planned"
    fi
  else
    ln --symbolic \
       --relative \
       "${TARGET}" \
       "${LINKNAME}"
  fi
done < "${MAKE_LINKS_FILE}"

###############################################################################
# - Make all specified directories
#   - <TODO>: Ensure the user isn't trying to make directories that are not
#   subdirs of the current directory (? how to do this and deal with links to
#   external directories)
#   - If <DNAME> is some other type of path, eg an existing file, mkdir will
#   fail and kill the current script
while read -r DNAME;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${DNAME}" ]] || [[ "${DNAME:0:1}" == "#" ]];
  then
    continue
  fi

  # If the directory does not exist, make it and any intermediate dirs
  if [[ ! -d "${DNAME}" ]];
  then
    mkdir -p "${DNAME}"
  fi
done < "${MAKE_DIRS_FILE}"

###############################################################################
# - Local copies of external files
#
# - We set up copies of any specified files. The user-provided file should be
# whitespace-spearated with two filenames on each line:
#   - 1) the original file that is to be copied; and
#   - 2) the location that the file should be copied to.
#
# - For copies (as for links):
#   - ignore blank lines
#   - die if either originalfile or copyfile is blank
#   - if the copyfile exists, do NOT rewrite it (to ensure that the current
#   project has a time-fixed version of the file/script although the original
#   file/script may be updated for use in other projects, for example).
#   - check that the originalfile is a file and die if it isn't
while read -r LINE;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${LINE}" ]] || [[ "${LINE:0:1}" == "#" ]];
  then
    continue
  fi

  # Split the line into originalfile and copyfile;
  #   - die if either are emptystrings
  #   - check that there are only two entries on the line
  ARY=(${LINE})
  {% raw -%}
  if [[ ${#ARY[@]} -ne 2 ]] || \
     [[ -z "${ARY[0]}" ]]   || \
     [[ -z "${ARY[1]}" ]];
  then
    die_and_moan \
    "${0}: Couldn't parse target-name and link-name from '${LINE}' \
    \n ... make sure there's no spaces in your filenames"
  fi
  {%- endraw %}

  ORIGINAL=$( expand_tilde "${ARY[0]}" )
  COPYFILE=$( expand_tilde "${ARY[1]}" )

  # The directory in which the copy is to be placed should be made if it
  #   doesn't exist
  COPYDIR=$(dirname  "${COPYFILE}")
  if [[ ! -d "${COPYDIR}" ]];
  then
    mkdir -p "${COPYDIR}"
  fi

  # If the copyfile is already in existence, do not overwrite it
  if [[ -e "${COPYFILE}" ]];
  then
    continue
  fi

  # Check that the original file is an existing file and die if not
  if [[ ! -f "${ORIGINAL}" ]];
  then
    die_and_moan \
    "${0}: original file '${ORIGINAL}' isn't an existing file and was to be \
     \n ... copied"
  fi

  cp "${ORIGINAL}" "${COPYFILE}"

done < "${MAKE_FILE_COPIES_FILE}"

###############################################################################
# - Local copies of external directories
#
# - We set up copies of any specified dirs. The user-provided file should be
# whitespace-spearated with two dirnames on each line:
#   - 1) the original dir that is to be copied; and
#   - 2) the location that the dir should be copied to.
#
# - For copies (as for links):
#   - ignore blank lines
#   - die if either originalfile or copyfile is blank
#   - if the copy-location exists, do NOT rewrite it (to ensure that the
#   current project has a time-fixed version of the file/script although the
#   original file/script may be updated for use in other projects, for
#   example).
#   - check that the original-location is a dir and die if it isn't
while read -r LINE;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${LINE}" ]] || [[ "${LINE:0:1}" == "#" ]];
  then
    continue
  fi

  # Split the line into original-location and copy-location;
  #   - die if either are emptystrings
  #   - check that there are only two entries on the line
  ARY=(${LINE})
  {% raw -%}
  if [[ ${#ARY[@]} -ne 2 ]] || \
     [[ -z "${ARY[0]}" ]]   || \
     [[ -z "${ARY[1]}" ]];
  then
    die_and_moan \
    "${0}: Couldn't parse target-name and link-name from '${LINE}' \
    \n ... make sure there's no spaces in your filenames"
  fi
  {%- endraw %}

  ORIGINAL_LOC=$( expand_tilde "${ARY[0]}" )
  COPY_LOC=$( expand_tilde "${ARY[1]}" )

  # The directory in which the copy is to be placed should be made if it
  #   doesn't exist
  COPY_PARENT_DIR=$(dirname  "${COPY_LOC}")
  if [[ ! -d "${COPY_PARENT_DIR}" ]];
  then
    mkdir -p "${COPY_PARENT_DIR}"
  fi

  # If the copy-location is already in existence, do not overwrite it
  if [[ -e "${COPY_LOC}" ]];
  then
    continue
  fi

  # Check that the original is an existing directory and die if not
  if [[ ! -d "${ORIGINAL_LOC}" ]];
  then
    die_and_moan \
    "${0}: original dir '${ORIGINAL_LOC}' isn't an existing directory and was \
    \n ... to be copied"
  fi

  rsync -a \
    --exclude=".git" \
    --exclude=".gitignore" \
    "${ORIGINAL_LOC}" \
    "${COPY_LOC}"

done < "${MAKE_DIR_COPIES_FILE}"

###############################################################################

REPO_CLONING_SCRIPT="${BUDDY_PY}/buddy/setup_git_clones.py"

if [[ ! -f "${REPO_CLONING_SCRIPT}" ]];
then
  die_and_moan \
  "${0}: git cloning script: '${REPO_CLONING_SCRIPT}' is not available"
fi

python3 "${REPO_CLONING_SCRIPT}" "${REPO_CLONING_CONFIG}"

###############################################################################
# After copying all files / making all links / setting up all dirs if a
# filename is present in the file "TOUCH_THESE_FILES" but is not an existing
# file within the directory, touch the given filename.
#
while read -r LINE;
do
  # Ignore blanks and
  # .. ignore lines if they start with '#' (ie, comment lines)
  if [[ -z "${LINE}" ]] || [[ "${LINE:0:1}" == "#" ]];
  then
    continue
  fi

  # touch the file
  FILENAME=${LINE}
  if [[ ! -f "${FILENAME}" ]];
  then
    touch "${FILENAME}"
  fi

done < "${TOUCH_FILES_FILE}"

###############################################################################
