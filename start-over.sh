#!/bin/bash

# Function to `find` and cleanup non-DOS files.
# Skip .bat files, the .git/ directory, and this script file itself (start-over.sh)
function cleanupNonDosFiles() {
  find . -path ./.git -prune -o \( -not -iname '*.bat' -a -not -name '*start-over.sh*' \) -a -exec dos2unix {} &> /dev/null \;
  #find . -path ./.git -prune -o \( -not -iname '*.bat' -a -not -name '*start-over.sh*' \) -a -print -exec dos2unix {} 1> /dev/null \;
  #find . -type f -not -name '*.bat' -a -not './start-over.sh' -a -not -path './.git/*' -exec dos2unix {} 1> /dev/null \;
}
# -not -iname

# Figure out the branch name to use, if first choice is already taken
startOverBranchName="";
startOverBranchNameDefault="start-over";
for suffix in "" _{01..99}; do
  putative_startOverBranchName="${startOverBranchNameDefault}${suffix}";
  check_putative_startOverBranchName="`git branch | egrep \"^..${putative_startOverBranchName}\$\"`";
  if [ -z "${check_putative_startOverBranchName}" ]; then
    startOverBranchName="${putative_startOverBranchName}";
    break;
  fi;
done;

if [ -n "${startOverBranchName}" ]; then
  echo "Using 'start over' branch name '${startOverBranchName}'";
else
  echo "Error: failed to choose a 'start over' branch name to use";
  exit;
fi;
# Checkout a new branch from the first commit
firstCommit="`git log --format=format:%h | tail -1`";
git checkout -b ${startOverBranchName} ${firstCommit};

# Commit to perform cleanup till
targetCommit="next";
#targetCommit="8a1b8e6b9";
#targetCommit="a585f5274";

#set -v
#set -x

# Iterate the commits from firstCommit (already checked out) till targetCommit,
# perform cleanup on each.
# Re-commit the cleaned-up version with the same commit details.
# Note that the first commit might not have any files, and thus might give git error msg
#   error: pathspec '.' did not match any file(s) known to git
for c in `git log --format=format:%h%n ${targetCommit} | tac`; do
  echo "commit ${c} - checking out working tree";
  #git checkout ${c} -- .;
  git checkout ${c} .;
  echo "   checked out";
  cleanupNonDosFiles;
  echo "   cleaned up";
  git add -u;
  echo "   updates added";
  git commit -C ${c} 1> /dev/null;
  echo "   updates committed";
  echo "   cleanup of working tree completed";
done;
