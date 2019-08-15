#!/bin/bash
#
# Lucas A. Miranda 2019
# https://github.com/lucas-miranda
#

containsValue() {
    values=("$2")
    for value in "${values[@]}"
    do
        if [ "$value" == "$1" ]
        then
            return 1
        fi
    done

    return 0
}

showHelp() {
    echo "Usage: move_files TARGET_DIR [OPTION]...

Options:
  -i, --ignore [FILENAME]   Ignore filename
  -v, --verbose             Make program be more talkactive
  -h, --help                Show this message"
}

loading_icon() {
    case "$1" in
        "0")
            echo "|"
            return 1
            ;;
        "1")
            echo "/"
            return 2
            ;;
        "2")
            echo "-"
            return 3
            ;;
        "3")
            echo "\\"
            return 4
            ;;
        "4")
            echo "|"
            return 5
            ;;
        "5")
            echo "/"
            return 6
            ;;
        "6")
            echo "-"
            return 7
            ;;
        "7")
            echo "\\"
            return 0
            ;;
        *)
            echo "|"
            ;;
    esac

    return 0
}

update_progress() {
    if [ "$3" == "" ] || [ "$3" -le "-1" ] 
    then
        echo "Copied  $1, Ignored  $2                 "
    else
        progress_icon=$(loading_icon $3)
        loading_id=$?
        echo -ne "Copied  $1, Ignored  $2 $progress_icon \r"
        return $loading_id
    fi

    return 0
}

# args

verbose=false
ignore_filenames=()

if [ -d "$1" ]
then
    echo "Moving to '$1'"
else
    echo "Sadly, '$1' wasn't found or isn't a directory."
    exit 1
fi

for ((i = 2; i <= $#; i++))
do
    arg=${!i}

    if [ "$arg" == "-i" ] || [ "$arg" == "--ignore" ]
    then
        next_i=$(($i + 1))

        if [ "$next_i" -le "$#" ]
        then
            value=$next_i
            ignore_filenames+=("${!value}")
        fi
    elif [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]
    then
        verbose=true
    elif [ "$arg" == "-h" ] || [ "$arg" == "--help" ]
    then
        exit 0
    fi
done

#

loading_id=0

files=$()
files_to_move=()

files_copied=0
files_ignored=0

if ! $verbose
then
    update_progress $files_copied $files_ignored $loading_id
    loading_id=$?
fi

while read -r filename
do
    containsValue $filename "${ignore_filenames[@]}"
    should_be_ignored=$?

    if [ $should_be_ignored -eq "0" ]
    then
        cp "$filename" -t $1
        if $verbose
        then
            echo "Copied: $filename"
        else
            files_copied=$((files_copied + 1))
        fi
    else
        if $verbose
        then
            echo "Ignored: $filename"
        else
            files_ignored=$((files_ignored + 1))
        fi
    fi

    if ! $verbose
    then
        update_progress $files_copied $files_ignored $loading_id
        loading_id=$?
    fi
done <<EOT
$(ls.exe | grep --extended-regexp ".+\.(exe|dll|xml|pdb)")
EOT

if ! $verbose
then
    update_progress $files_copied $files_ignored 
fi
