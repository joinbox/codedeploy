#




1. checks out master in apps/vendor/repository/branch -> apps/joinbox/eb-soa/master
2. launches pre release script
    3. checks if the .hosting file exists in all branches
    4. checks all branches out, into the correct folder
    5. set up the projects config (copy from repository folder if not already present)
    6. sets up nginx config 
    7. sets up the upstart script using info from the .hosting file
    8. starts server
    9 reloads nginx

