#!/bin/bash

# Identify this script file
thisScript="`basename ${0}`";
if [ ! -r ${thisScript} ]; then exit; fi;

# Function to `find` and cleanup non-DOS files.
# Skip (all *.bat files), (the .git/ directory), and (this script file itself (start-over.sh))
function cleanupNonDosFiles() {
  find . -path ./.git -prune -o \( -not -iname '*.bat' -a -not -name '*start-over.sh*' \)    -exec dos2unix {} &> /dev/null \;
}

# Verify that the differences between two commits ${c} and ${latestStartOverCommit} is only modified files
function verifyDiffIsOnlyMods() {
  [ -z "${c}" -o -z "${latestStartOverCommit}" ] && echo 'Missing environment var ${c} and/or ${latestStartOverCommit}' && exit 1;
 echo ${thisScriptCopy};
  set +e; # turn off 'exit on error' since grep returns exit code '1' on no lines being found
  diffCmd="git diff --name-status '${c}' '${latestStartOverCommit}' | egrep -v '^M' | egrep -v '^A\s${thisScriptCopy}'";
 echo "\${diffCmd}: '${diffCmd}'";
  diffOutput="`eval ${diffCmd}`";
  set -e; # turn back on 'exit on error'
  if [ -n "${diffOutput}" ]; then
    diffOutput_indented="`echo ${diffOutput} | sed -e 's@^@  @'`";
    errorEcho "The diff between the source commit and the cleaned-up commit";
    errorEcho "  ${diffCmd}";
    errorEcho "includes added or removed files, including:";
    # echo initial and trailing lines of the diffOutput
    # Note: to make sure leading whitespace is not lost, ensure that
    #   ${diffOutput_indented} and the excerpt vars are wrapped in
    #    double-quotes when being echo'd
    headExcerpt="`echo \"${diffOutput_indented}\" | head -2`";
    errorEcho "${headExcerpt}";
    tailExcerpt="`echo ${diffOutput_indented} | tail +2 | tail -2`";
    if [ -n "${tailExcerpt}" ]; then
      errorEcho "...";
      errorEcho "${tailExcerpt}";
    fi;
    errorEcho "This is unexpected. Exiting.";
    exit 1;
  fi;
}

# Set/Update the value of 'latestStartOverCommit' to the latest commit.
# This should be the latest commit on our 'start over' branch.
# Be careful to only do this/use this value when we are on that chain, avoid
# using it when we are in the middle of some fancy `git reset` sequence or
# other fanciness to help us pull in all changes from the source commit.
function updateLatestStartOverCommit() {
  latestStartOverCommit="`git log -1 --format=format:%h`";
}

# Functions to help with logging
export BRIGHT_RED="$(tput bold)$(tput setaf 1)";
export BRIGHT_YELLOW="$(tput bold)$(tput setaf 11)";
export FAINT_PURPLE="$(tput bold)$(tput setaf 93)";
export TPUT_RESET="$(tput sgr0)";

export COMMIT_LINE_COLOR="${BRIGHT_YELLOW}";
export DATE_COLOR="${FAINT_PURPLE}";
export ERROR_COLOR="${BRIGHT_RED}";

function commitLineEcho() { echo "${COMMIT_LINE_COLOR}${@}${TPUT_RESET}"; }
function dateEcho()       { echo "${DATE_COLOR}${@}${TPUT_RESET}";        }
function errorEcho()      { echo "${ERROR_COLOR}${@}${TPUT_RESET}";       }

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
done;

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
#endingCommit="8a1b8e6b9"; # n=0
#endingCommit="3eca4d2de"; # n=3
#endingCommit="a585f5274"; # n=9

# For testing; ensure this commit that only adds files
#endingCommit="10a9d2e11"; # n=1839
#startingCommit="0b107dbb1"; # n=1836

# Identify the commit to start mimicking.
startingCommit="`git log --format=format:%h ${endingCommit} | tail -1`";
git checkout -b ${startOverBranchName} ${startingCommit} || exit 1;
thisScriptCopy="${thisScript}_${suffix}";
cp "${thisScript}" "${thisScriptCopy}";
git add "${thisScriptCopy}";
git commit -m 'add a copy of this script being used to "start over"';
updateLatestStartOverCommit;

# Iterate the commits from startingCommit (already checked out) till
# endingCommit, perform cleanup on each. Create a new commit of the cleaned-up
# version with the same commit details.
# Since the 1st commit (8a1b8e6b9 'Initial import.') in this SoapUI repo is
# empty (no files), it is okay to skip the 1st commit.
# i.e., git checkout gives git error with msg:
#   error: pathspec '.' did not match any file(s) known to git
n=$((0));
for c in `git log --format=format:%h%n ${startingCommit}..${endingCommit} | tac`; do
  n=$((n+1));
  commitLineEcho "${c} (${n}) - checking out this commit's index";
  dateEcho "   `date`";
  # Reset '--hard' to the current source commit, then pull in all it's changed
  # with a '--mixed' reset on top of the most recent 'start over' commit
  git reset --hard ${c};
  git reset --mixed "${latestStartOverCommit}" 1> /dev/null;
  echo "   files cleaned up";
  cleanupNonDosFiles;
  echo "   git add -A";
  git add -A;
  git reset *${thisScript}*; # ensure this script and its backup/.swp files aren't added
  echo "   git commit";
  git commit --allow-empty --allow-empty-message -C ${c} 1> /dev/null;
  echo "   attempting to verify changes...";
  updateLatestStartOverCommit;
  verifyDiffIsOnlyMods
  echo "   processing this commit is completed";
done;
