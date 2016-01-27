#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# args passed
vendor=$1
repository=$2
remote="git@github.com:$vendor/$repository.git"



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





# check out a fresh copy
masterPath="$HOME/apps/$vendor/$repository/master"

if [ ! -d "$masterPath" ]; then
    echo -e "\e[92mCloning into $masterPath\033[0m"
    mkdir -p "$masterPath"
    cd "$masterPath"
    git clone "$remote" ./
else
    cd "$masterPath"
fi



# get all branches as array
read -a branches <<<$(git branch -r | cut -c 10- | tail -n +2)

# loop over all branches
for branch in "${branches[@]}"; do

    cd "$masterPath"

    # check if the branch wants to be deployed
    git cat-file -e "origin/$branch:.deploy/deploy.sh" > /dev/null 2>&1
    if [ $? -eq 0 ]; then

        # define paths
        branchPath="$HOME/apps/$vendor/$repository/$branch"
        repoPath="$HOME/apps/$vendor/$repository"
        serviceName=$(echo "$vendor_$repository_$branch" | sed -r 's/([a-z]+)_([a-z])([a-z]+)/\1\U\2\L\3/')

        

        echo -e "\e[92mChecking FOR branch $vendor/$repository:$branch ..."

        # create directories, clone git if required
        if [ ! -d "$branchPath" ]; then
            echo -e "\e[92mBranch $branch was not cloned before, checking out now ...\033[0m"
            
            mkdir -p "$branchPath"
            cd "$repoPath"
            git clone -b "$branch" "$remote" "./$branch"
            cd "$branchPath" 
        else
            echo -e "\e[92mUpdating branch $branch ...\033[0m"
            # update git
            cd "$branchPath"
            git pull origin "$branch"
        fi

       
       



        # execute install script if present
        if [ -f "$branchPath/.autorelease.staging.sh" ]; then
            echo -e "\e[92mExecuting the .autorelease.staging.sh file ...\033[0m"
            source "$branchPath/.autorelease.staging.sh"
        fi





        # check if we need to setup a nginx config
        if [ -f "$branchPath/.nginx.staging.conf" ]; then
            nginxConfig="/etc/nginx/site_available/$serviceName.conf"

            if [ ! -f "$nginxConfig" ]; then
                echo "\e[92mInstalling the nginx config file ...\033[0m"
                cp "$branchPath/.nginx.staging.conf" "$nginxConfig"

                # enable site
                ln -s "$nginxConfig" "/etc/nginx/sites_enabled/$serviceName.conf"
            fi

            # make sure nginx is running
            source "$scriptDir/assertNginx.sh"

            # reload
            service nginx reload
        fi





        # check if we need to setup a system service
        if [ -f "$branchPath/.service.staging.conf" ]; then
            serviceScript="/etc/init/$serviceName.conf"

            # do we need to install the service?
            if [ ! -f "$serviceScript" ]; then
                echo -e "\e[92mInstalling the service $serviceName ...\033[0m"
                cp "$branchPath/.service.staging.conf" "$serviceScript"
            fi

            # stop the service
            stop "$serviceName"

            ## start service
            start "$serviceName"
        fi
    fi
done
