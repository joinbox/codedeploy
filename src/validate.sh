#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# args passed
vendor=$1
repository=$2
installEnv=$3



# check parameters
if [ -z "$1" ]; then
    echo "parameter 1 to the the deployr command must be the vendor used as on github!"
    exit 1;
fi

# check parameters
if [ -z "$2" ]; then
    echo "parameter 2 to the the deployr command must be the repository used as on github!"
    exit 1;
fi

# check parameters
if [ -z "$3" ]; then
    echo "parameter 3 to the the deployr command must be the environment to deploy to!"
    exit 1;
fi


echo -e "\e[32mValidating deployment for $vendor/$repository and env $installEnv ...\033[0m"



# check out a fresh copy
masterPath="$HOME/apps/$vendor/$repository/master"

if [ ! -d "$masterPath" ]; then
    echo -e "\e[92mMaster not found: $masterPath\033[0m"
    exit 1
else
    cd "$masterPath"
fi





# get all branches as array
read -a branches <<<$(git branch -r | cut -c 10- | tail -n +2)

# add master
#branches+=('master')


# loop over all branches
for branch in "${branches[@]}"; do

    cd "$masterPath"

    # check if the branch wants to be deployed
    git cat-file -e "origin/$branch:.deploy" > /dev/null 2>&1
    if [ $? -eq 0 ]; then

        # define paths
        branchPath="$HOME/apps/$vendor/$repository/$branch"

        
        echo -e "\e[92mChecking for branch $vendor/$repository:$branch ..."

        # create directories, clone git if required
        if [ ! -d "$branchPath" ]; then
            echo -e "\e[92mBranch $branch was not cloned ...\033[0m"
            exit 1
        else
            cd "$branchPath"
        fi

       

        # execute install script if present
        if [ -f "$branchPath/.deploy/$installEnv/validate.sh" ]; then
            echo -e "\e[92mExecuting the $installEnv validate.sh file ...\033[0m"
            source "$branchPath/.deploy/$installEnv/validate.sh" $branchPath $scriptDir
        fi
    else
        echo -e "\e[33mBranch \e[34m$branch\e[33m has no .deploy folder, skipping it!\033[0m"
    fi
done

echo -e "\e[32mInstallation complete ...\033[0m"