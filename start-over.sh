#!/bin/bash

# Identify this script file
thisScript="`basename ${0}`";
if [ ! -r ${thisScript} ]; then exit; fi;

# Function to `find` and cleanup non-DOS files.
# Skip (all *.bat files), (the .git/ directory), and (this script file itself (start-over.sh))
function cleanupNonDosFiles() {
  find . -path ./.git -prune -o \( -not -iname '*.bat' -a -not -name '*start-over.sh*' \)    -exec dos2unix {} &> /dev/null \;
}

# Verify that the differences between two commits ${commitA} and ${commitB} is only modified files
function verifyDiffIsOnlyMods() {
  [ -z "${commitA}" -o -z "${commitB}" ] && echo 'Missing environment var ${commitA} and/or ${commitB}';
 echo ${thisScriptCopy};
  #diffVerifyCmd="git diff --name-status \"${commitA}\" \"${commitB}\" | egrep -v '^M' | egrep -v \"^A\s${thisScriptCopy}\"";
  set +e; # turn off 'exit on error' since grep returns exit code '1' on no lines being found
  diffVerifyCmd="git diff --name-status '${commitA}' '${commitB}' | egrep -v '^M' | egrep -v '^A\s${thisScriptCopy}'";
  #d=`git diff --name-status "${commitA}" "${commitB}" | egrep -v '^M' | egrep -v "^A\s${thisScriptCopy}"`;
  #d="`git diff --name-status \"${commitA}\" \"${commitB}\" | egrep -v '^M' | egrep -v \"^A\s${thisScriptCopy}\"`";
  #d=`git diff --name-status "${commitA}" "${commitB}" | egrep -v '^M'`;
 echo "\${diffVerifyCmd}: '${diffVerifyCmd}'";
  d="`eval ${diffVerifyCmd}`";
  set -e; # turn back on 'exit on error'
 echo "\${d} = '${d}'";
  [ -z "${d}" ] || ( \
    echo ${d} | head && \
    echo "..." && \
    echo "Current 'git diff "${commitA}" "${commitB}"' includes non-modification. Exiting." \
    && exit 1 \
  );
 echo "done check...";
}

# Functions to help with logging
export BRIGHT_YELLOW="$(tput bold)$(tput setaf 11)";
export FAINT_PURPLE="$(tput bold)$(tput setaf 93)";
export TPUT_RESET="$(tput sgr0)";

export COMMIT_LINE_COLOR="${BRIGHT_YELLOW}";
export DATE_COLOR="${FAINT_PURPLE}";

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
  echo -n "   git checkout - ";
  git checkout --overlay ${c} .;
  echo "   files cleaned up";
  cleanupNonDosFiles;
  echo "   git add -A";
  git add -A;
  git reset *${thisScript}*; # ensure this script and its backup/.swp files aren't added
  echo "   git commit";
  git commit --allow-empty --allow-empty-message -C ${c} 1> /dev/null;
  echo "   attempting to verify changes...";
  commitA="${c}";
  commitB="`git log -1 --format=format:%h`";
  verifyDiffIsOnlyMods
  echo "   processing this commit is completed";
done;
