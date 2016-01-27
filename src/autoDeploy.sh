#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# args passed
vendor=$1
repository=$2
remote="git@github.com:$vendor/$repository.git"



# check parameters
if [ vendor == "" ]; then
    echo "parameter 1 to the the deployr command must be the vendor used as on github!"
    exit 1;
fi

# check parameters
if [ repository == "" ]; then
    echo "parameter 2 to the the deployr command must be the repository used as on github!"
    exit 1;
fi





# check out a fresh copy
mkdir -p "$HOME/apps/$vendor/$repository/master"
cd "$HOME/apps/$vendor/$repository/master"
git clone "$remote" ./



# get all branches as array
IFS=', ' read -r -a branches <<< $(git branch | cut -c 3-)

# loop over all branches
for branch in "${branches[@]}"; do
    branchPath="$HOME/apps/$vendor/$repository/$branch"
    serviceName=$("$vendor_$repository_$branch" | sed -r 's/([a-z]+)_([a-z])([a-z]+)/\1\U\2\L\3/')

    # dont check the files for master, we're there already
    if [ $branch != "master" ]; then
        echo "Checking branch $vendor/$repository:$branch ..."

        # create directories, clone git if required
        if [ ! -d "$branchPath" ]; then                
            echo "Branch $branch was not checked out before, checking out now ..."
            
            mkdir -p "$branchPath"
            cd "$branchPath"
            git clone "$remote" ./
            git checkout "$branch"
        fi
    fi



    # update git
    cd "$branchPath"
    git checkout "$branch"
    git pull origin "$branch"





    # execute install script if present
    if [ -f "$branchPath/.autorelease.staging.sh" ]; then
        echo "Executing the .autorelease.staging.sh file ..."
        source "$branchPath/.autorelease.staging.sh"
    fi





    # check if we need to setup a nginx config
    if [ -f "$branchPath/.nginx.staging.conf" ]; then
        nginxConfig="/etc/nginx/site_available/$serviceName.conf"

        if [ ! -f "$nginxConfig" ]; then
            echo "Installing the nginx config file ..."
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
            echo "Installing the service $serviceName ..."
            cp "$branchPath/.service.staging.conf" "$serviceScript"
        fi

        # stop the service
        stop "$serviceName"

        ## start service
        start "$serviceName"
    fi
done
