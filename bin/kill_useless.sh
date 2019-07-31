#!/bin/bash
#
# Lucas A. Miranda 2019
# https://github.com/lucas-miranda
#
# Kill useless process that uses graphics card processing
# even when isn't needed, of course it's a bash script 
# aimed to Windows use.
#

# options

icon_process_closed=''
icon_process_already_closed=''
icon_process_close_error=''

windows_useless_processes=(
    'HxCalendarAppImm.exe'
    'MicrosoftEdge.exe'
    'winstore.app.exe'
    'microsoft.photos.exe'
    'calculator.exe'
    'onenoteim.exe'
    'windowsinternal.composableshell.experiences.textinput.inputapp.exe'
    'lockapp.exe'
)

# args

verbose=false
kill_process_tree=false

for arg in $*
do
    if [ "$arg" == "-t" ] || [ "$arg" == "--tree" ]
    then
        kill_process_tree=true
    elif [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]
    then
        verbose=true
    elif [ "$arg" == "-h" ] || [ "$arg" == "--help" ]
    then
        echo "Usage: kill_useless [OPTION]...
  Kill useless process that uses graphics card processing even when isn't needed.
  And, of course, it's a program focused at Windows.

Options:
  -t, --tree      Close processes and any child process
  -v, --verbose   Make program be more talkactive
  -h, --help      Show this message"
        exit 0
    fi
done

#

if [ "$OSTYPE" == "win32" ] || [ "$OSTYPE" == "cygwin" ] || [ "$OSTYPE" == "msys" ]
then
    if $verbose
    then
        echo "Killing useless processes..."
    fi

    for process_name in "${windows_useless_processes[@]}"
    do
        if $verbose
        then
            echo ""
            echo "Looking for pid of process with name: $process_name"
        fi

        pid=$(ps -W -s | awk "{ if (index(tolower(\$0), tolower(\"$process_name\")) != 0) { print \$1 } }")
        process_extra_info=""

        if [ ! -z "$pid" ]
        then
            if $kill_process_tree
            then
                if $verbose
                then
                    echo "Running taskkill (with /t)..."
                fi

                taskkill //pid $pid //f //t &> /dev/null
            else
                if $verbose
                then
                    echo "Running taskkill..."
                fi

                taskkill //pid $pid //f &> /dev/null
            fi

            # confirm if process is really dead (better than using taskkill terrible output)
            info=$(ps -W -s | grep $pid)

            if [ -z "$info" ]
            then
                if $verbose
                then
                    echo "Process closed successfully!"
                fi

                icon_process_status=$icon_process_closed
                process_extra_info="(pid: $pid)"
            else
                if $verbose
                then
                    echo "Process can't be closed."
                fi

                icon_process_status=$icon_process_close_error
            fi
        else
            if $verbose
            then
                echo "Process is already closed."
            fi

            icon_process_status=$icon_process_already_closed
        fi

        echo "$icon_process_status $process_name $process_extra_info"
    done
else
    echo "OS '$OSTYPE' not supported."
fi

