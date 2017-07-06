#!/bin/bash

#TODO use 'git rev-parse --is-inside-work-tree' to check if inside a git repo
#TODO add stroom-resources to the list of repos to pull down.  If inside stroom-resources repo
#drop down two levels and run else run where you are, then the script can be run from 
#curlign down from github.

GIT_PREFIX="https://github.com/"
REPO_USER="gchq"
GIT_BRANCH_STATUS_SCRIPT="stroom-resources/bin/git-branch-status.sh"

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

cloneOrUpdate() {
    [ ! "$#" -eq 1 ] && echo "Missing arg to cloneOrUpdate" && exit 1
    repo=$1
    echo ""
    if [[ -d "${repo}" ]]; then
        if [[ -d "${repo}/.git" ]]; then
            cd "${repo}" 

            if [[ -x "../$GIT_BRANCH_STATUS_SCRIPT" ]]; then
                echo -e "Branch status for \e[96m${repo}\e[0m (shows nothing if all branches are in synch):"
                #TODO not sure if we want to do a fetch here
                #git fetch --all
                source ../$GIT_BRANCH_STATUS_SCRIPT -am
            else
                # Update the repo
                echo -e "Performing a fetch on repo \e[96m${repo}\e[0m"
                git fetch --all
            fi

            cd ..
        else
            echo -e "Non-git directory already exists with name \e[96m${repo} \e[0m, doing nothing"
        fi
    else
        # Clone the repo
        echo -e "Cloning \e[96m${repo} \e[0m"
        git clone ${GIT_PREFIX}${REPO_USER}/${repo}.git
    fi
}

cloneOrUpdateAllRepos() {
    # We need to be cloning siblings of stroom-resources, and this script resides in stroom-resources/bin
    #cd ../..

    cloneOrUpdate stroom
    cloneOrUpdate stroom-agent
    cloneOrUpdate stroom-auth
    cloneOrUpdate stroom-clients
    cloneOrUpdate stroom-content
    cloneOrUpdate stroom-docs
    cloneOrUpdate stroom-expression
    cloneOrUpdate stroom-proxy
    cloneOrUpdate stroom-query
    cloneOrUpdate stroom-resources
    cloneOrUpdate stroom-stats
    cloneOrUpdate stroom-visualisations-dev

    cloneOrUpdate event-logging
    cloneOrUpdate event-logging-schema

    cloneOrUpdate urlDependencies-plugin

    # We don't necessarily need the shaded repos because we pull these dependencies
    # down using urlDependencies-plugin
    cloneOrUpdate hadoop-common-shaded
    cloneOrUpdate hadoop-hdfs-shaded
    cloneOrUpdate hbase-common-shaded

    # Are these defunct?
    #cloneOrUpdate stroom-timeline
    #cloneOrUpdate stroom-timeline-loaded
    #cloneOrUpdate stroom-shaded-dependencies
}
isInsideGitRepo=$(git rev-parse --is-inside-work-tree 2>/dev/null)
repoDir=$(git rev-parse --show-toplevel 2>/dev/null)
repoName=$(basename ${repoDir} 2>/dev/null)

if [[ $isInsideGitRepo ]] && [[ $repoName = "stroom-resources" ]]; then 
    #cd to the parent of the current repo so we can clone the other repos
    #alongside it
    pushd ${repoDir}/..
elif [[ $isInsideGitRepo ]] && [[ ! $repoName = "stroom-resources" ]]; then 
    echo "Currently inside a git repository that we don't recognise. Run this script from within stroom-resources or from a directory that is not a git repository"
    exit 1
fi

while true; do
    echo "This will clone or pull all Stroom related repos from "
    echo "  ${GIT_PREFIX}${REPO_USER}" 
    echo "into $(pwd)"
    read -p "Are you sure you want to do this? [y/n]" yn
    case $yn in
        [Yy]* ) cloneOrUpdateAllRepos; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

popd 2>/dev/null
