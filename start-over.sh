#!/bin/bash

# Function to `find` and cleanup non-DOS files.
function cleanupNonDosFiles() {
  find . -type f -not -name '*.bat' -not -path './.git/*' -exec dos2unix {} \;
}

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

# Iterate the commits from firstCommit (already checked out) till targetCommit,
# perform cleanup on each.  Re-commit the cleaned-up version with the same
# commit details.
for c in `git log --format=format:%h ${targetCommit} | tac`; do
  echo "commit ${c} - checking out working tree";
  git checkout ${c} .;
  echo "commit ${c} -   checked out";
  cleanupNonDosFiles();
  echo "commit ${c} -   cleaned up";
  git add -u;
  echo "commit ${c} -   updates added";
  git commit --amend --no-edit;
  echo "commit ${c} -   updates committed";
  echo "commit ${c} - cleanup of working tree completed";
done;
