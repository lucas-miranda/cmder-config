#!/bin/bash
#
# Lucas A. Miranda 2019
# https://github.com/lucas-miranda
#
# Checks multiple git repositories
# and handle that information
#

origin_path="$(pwd)"
git_folders=()

for ((i = 1; i <= $#; i++))
do
    arg=${!i}
    git_folders+=("$arg")
done

###

for git_folder in "${git_folders[@]}"
do
    cd $git_folder

    status=$(git --no-optional-locks status --porcelain)

    if [ "$status" == "" ]
    then
        echo -e "\e[36m●\e[0m $git_folder" 
    else
        echo -e "\e[33m●\e[0m $git_folder" 
    fi

    cd $origin_path
done

