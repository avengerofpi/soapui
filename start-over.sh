#!/bin/bash

# Identify this script file
thisScript="`basename ${0}`";
if [ ! -r ${thisScript} ]; then exit; fi;

# Function to `find` and cleanup non-DOS files.
# Skip (all *.bat files), (the .git/ directory), and (this script file itself (start-over.sh))
function cleanupNonDosFiles() {
  find . -path ./.git -prune -o \( -not -iname '*.bat' -a -not -name '*start-over.sh*' \)    -exec dos2unix {} &> /dev/null \;
}

# Functions to help with logging
export BRIGHT_YELLOW="$(tput bold)$(tput setaf 11)"
export FAINT_PURPLE="$(tput bold)$(tput setaf 93)"
export TPUT_RESET="$(tput sgr0)"

export COMMIT_LINE_COLOR="${BRIGHT_YELLOW}"
export DATE_COLOR="${FAINT_PURPLE}"

function commitLineEcho() { echo "${COMMIT_LINE_COLOR}${@}${TPUT_RESET}"; }
function dateEcho()       { echo "${DATE_COLOR}${@}${TPUT_RESET}";        }

# Figure out the branch name to use, if first choice is already taken
startOverBranchName="";
startOverBranchNameDefault="start-over";
for suffix in {00..99}; do
  putative_startOverBranchName="${startOverBranchNameDefault}_${suffix}";
  check_putative_startOverBranchName="`git branch | egrep \"^..${putative_startOverBranchName}\$\"`";
  if [ -z "${check_putative_startOverBranchName}" ]; then
    startOverBranchName="${putative_startOverBranchName}";
    break;
  fi;
done

# Exit script if there is an error
set -e;
# Print shell input lines as they are read.
#set -v;

# Report the branch name that will be used
if [ -n "${startOverBranchName}" ]; then
  echo "Using 'start over' branch name '${startOverBranchName}'";
else
  echo "Error: failed to choose a 'start over' branch name to use";
  exit;
fi;

# Identify the commit we want to perform cleanup until
endingCommit="next";
#endingCommit="8a1b8e6b9";
#endingCommit="a585f5274";

# Identify the commit to start mimicking.
startingCommit="`git log --format=format:%h ${endingCommit} | tail -1`";
git checkout -b ${startOverBranchName} ${startingCommit} || exit 1;
thisScriptCopy="${thisScript}_${suffix}";
cp "${thisScript}" "${thisScriptCopy}";
git add "${thisScriptCopy}";
git commit -m 'add a copy of this script being used to "start over"';

# Iterate the commits from startingCommit (already checked out) till
# endingCommit, perform cleanup on each. Create a new commit of the cleaned-up
# version with the same commit details.
# Since the 1st commit (8a1b8e6b9 'Initial import.') in this SoapUI repo is
# empty (no files), it is okay to skip the 1st commit.
# i.e., git checkout gives git error with msg:
#   error: pathspec '.' did not match any file(s) known to git
for c in `git log --format=format:%h%n ${startingCommit}..${endingCommit} | tac`; do
  commitLineEcho "${c} - checking out this commit's index";
  dateEcho "   `date`";
  echo -n "   git checkout - ";
  git checkout ${c} .;
  echo "   files cleaned up";
  cleanupNonDosFiles;
  echo "   git add -A";
  git add -A;
  git reset *${thisScript}*; # ensure this script and its backup/.swp files aren't added
  echo "   git commit";
  git commit --allow-empty -C ${c} 1> /dev/null;
  echo "   processing this commit is completed";
done;
