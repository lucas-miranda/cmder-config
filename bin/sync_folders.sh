#!/bin/bash
#
# Lucas A. Miranda 2019
# https://github.com/lucas-miranda
#

#
# sync_folders source/ target/ 
#

find="C:/Program Files/Git/usr/bin/find.exe"

# standard icons 

file_unknown_std_icon="!"
file_error_std_icon="x"
file_copied_std_icon="+"
file_okay_std_icon="*" # it doesn't need to be copied again

# special icons 

file_unknown_special_icon=""
file_error_special_icon=""
file_copied_special_icon=""
file_okay_special_icon="" # it doesn't need to be copied again

###

show_help() {
    echo "Usage: sync_folders SOURCE_FOLDER TARGET_FOLDER [OPTIONS]...

Options:
  -s, --std-icon            Use standard icons
  -f, --force               Force file copy, even if it 
                            already exists
  -v, --verbose             Make program be more talkactive
  -h, --help                Show this message"
}

###

source_folder=$1
target_folder=$2
verbose=false
force=false
standard_icons=false

###

for ((i = 3; i <= $#; i++))
do
    arg=${!i}

    if [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]
    then
        verbose=true
    elif [ "$arg" == "-f" ] || [ "$arg" == "--force" ]
    then
        force=true
    elif [ "$arg" == "-s" ] || [ "$arg" == "--std-icon" ]
    then
        standard_icons=true
    elif [ "$arg" == "-h" ] || [ "$arg" == "--help" ]
    then
        show_help
        exit 0
    fi
done

###

echo "Source: $source_folder"
echo "Target: $target_folder"

modified_files=0
verified_files=0
error_files=0

while IFS= read -r -d ';' file
do
    icon=$file_unknown_icon
    copy_file=false

    if [ -f "$target_folder/$file" ]
    then
        filesize=$(stat -c %s "$source_folder/$file")
        last_modification=$(stat -c %Y "$source_folder/$file")
        target_filesize=$(stat -c %s "$target_folder/$file")
        target_last_modification=$(stat -c %Y "$target_folder/$file")

        if [ "$last_modification" -ne "$target_last_modification" ] || [ "$filesize" -ne "$target_filesize" ]
        then
            copy_file=true
        fi
    else
        copy_file=true
    fi

    if $copy_file
    then
        cp "$source_folder/$file" -T "$target_folder/$file"

        if [ -f "$target_folder/$file" ]
        then
            if $standard_icons
            then
                icon=$file_copied_std_icon
            else
                icon=$file_copied_special_icon
            fi

            modified_files=$((modified_files + 1)) 
        else
            if $standard_icons
            then
                icon=$file_error_std_icon
            else
                icon=$file_error_special_icon
            fi

            error_files=$((error_files + 1)) 
        fi
    else
        if $standard_icons
        then
            icon=$file_okay_std_icon
        else
            icon=$file_okay_special_icon
        fi

        verified_files=$((verified_files + 1)) 
    fi

    if $verbose
    then
        echo "$icon $file"
    fi
done <<EOT
$("$find" "$source_folder" -type f -printf '%P;')
EOT

echo "Modified  $modified_files, Verified  $verified_files, Error  $error_files"
