#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp "$scriptDir/src/deployr" /usr/bin/deployr
chmod +x /usr/bin/deployr