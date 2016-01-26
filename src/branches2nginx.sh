#!/bin/bash

confDir="/etc/nginx/sites-available"

# get current branch name
branch_name=$(git symbolic-ref -q HEAD)
branch_name=${branch_name##refs/heads/}
branch_name=${branch_name:-HEAD}

# get vendor
vendor="$(git config --get remote.origin.url | sed -n 's#.*:\([a-zA-Z0-9_\-]*\)/.*#\1#p')"
repository="$(git config --get remote.origin.url | sed -n 's#.*/\([a-zA-Z0-9_\-]*\).git#\1#p')"
remote=$(git config --get remote.origin.url)




# check if we're on master
if [ $branch_name == "master" ]; then
    echo "We are on the master branch on $vendor/$repository, checking other branches!"

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
        if [ -f "$branchPath/.autorelease.staging" ]; then
            echo "Executing the .autorelease file ..."
            source "$branchPath/.autorelease"
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
            source ./assertNginx.sh

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
fi
