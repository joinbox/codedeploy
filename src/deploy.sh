#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# args passed
vendor=$1
repository=$2
installEnv=$3
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

# check parameters
if [ -z "$3" ]; then
    echo "parameter 3 to the the deployr command must be the environment to deploy to!"
    exit 1;
fi


echo -e "\e[32mAutodeploy for $vendor/$repository and env $installEnv initialized ...\033[0m"



# check out a fresh copy
masterPath="$HOME/apps/$vendor/$repository/master"

if [ ! -d "$masterPath" ]; then
    echo -e "\e[92mCloning into $masterPath\033[0m"
    mkdir -p "$masterPath"
    cd "$masterPath"
    git clone "$remote" ./
else
    cd "$masterPath"
    git pull
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
        repoPath="$HOME/apps/$vendor/$repository"
        serviceName=$(echo "$vendor_$repository_$branch" | sed -r 's/([a-z]+)_([a-z])([a-z]+)/\1\U\2\L\3/')

        
        echo -e "\e[92mChecking for branch $vendor/$repository:$branch ..."

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
        if [ -f "$branchPath/.deploy/$installEnv/release.sh" ]; then
            echo -e "\e[92mExecuting the $installEnv release.sh file ...\033[0m"
            source "$branchPath/.deploy/$installEnv/release.sh" $branchPath $scriptDir
        fi





        # check if we need to setup a nginx config
        if [ -d "$branchPath/.deploy/$installEnv/nginx" ]; then

            # make sure nginx is running
            # source "$scriptDir/assertNginx.sh"


            dir="$branchPath/.deploy/$installEnv/nginx/*"

            for filePath in $dir
            do
                fileName=$(basename "$filePath")
                echo -e "\e[92mInstalling the nginx host $fileName ...\033[0m"

                # replace config, create symlink
                sudo cp $filePath "/etc/nginx/sites-available/$fileName"

                if [ ! -L "/etc/nginx/sites-enabled/$fileName" ]; then
                    sudo ln -s "/etc/nginx/sites-available/$fileName" "/etc/nginx/sites-enabled/$fileName"
                fi
            done

            # reload
            sudo service nginx reload
        fi




        # check if upstart is used
        [[ `/sbin/init --version` =~ upstart ]] > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            # check if we need to setup a system service
            if [ -d "$branchPath/.deploy/$installEnv/upstart" ]; then

                dir="$branchPath/.deploy/$installEnv/upstart/*"

                for filePath in $dir
                do
                    fileName=$(basename "$filePath")
                    serviceName=$(basename "$filePath" .conf)

                    echo -e "\e[92mInstalling the upstart service $serviceName ...\033[0m"

                    sudo cp $filePath "/etc/init/$serviceName.conf"

                    # stop the service
                    sudo stop $serviceName

                    # start service
                    sudo start $serviceName
                done
            fi
        fi





        # systemd
        [[ `systemctl` =~ -\.mount ]] > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            # check if we need to setup a system service
            if [ -d "$branchPath/.deploy/$installEnv/systemd" ]; then

                dir="$branchPath/.deploy/$installEnv/systemd/*"

                for filePath in $dir
                do
                    fileName=$(basename "$filePath")
                    serviceName=$(basename "$filePath" .service)

                    echo -e "\e[92mInstalling the systemd service $serviceName ...\033[0m"

                    sed "s,%projectRoot,$branchPath,g" "$filePath" | sudo tee "/etc/systemd/system/$serviceName.service" > /dev/null

                    # reload systemclt
                    sudo systemctl daemon-reload

                    # stop the service
                    sudo systemctl stop $serviceName

                    # start service
                    sudo systemctl start $serviceName
                done
            fi
        fi
    else
        echo -e "\e[33mBranch \e[34m$branch\e[33m has no .deploy folder, skipping it!\033[0m"
    fi
done

echo -e "\e[32mInstallation complete ...\033[0m"