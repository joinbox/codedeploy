#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

nodeVersion=$1
currentNodeVersion=$(node --version)

node --version > /dev/null
if [ $? -eq 0 ]; then

    # install ndoe
fi

source "$scriptDir/assertCompiler.sh"
source "$scriptDir/assertGit.sh"

sourcePath="$HOME/apps/nodejs/node/master"



# compile node?
if [ ! -d "$sourcePath" ]; then
    mkdir -p "$sourcePath"
    cd "$sourcePath"
    git clone https://github.com/nodejs/node.git ./

    # checkout the newest tag
    tag=$(git describe --abbrev=0)
    git checkout "$tag"

    # compile
    ./configure
    make
    sudo make install
fi
