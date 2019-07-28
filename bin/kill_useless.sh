#!/bin/bash
#
# Kill useless process that uses graphics card processing
# even when isn't needed, of course it's a bash script 
# aimed to Windows use.
#

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
    'notepad.exe'
)

if [ "$OSTYPE" == "win32" ] || [ "$OSTYPE" == "cygwin" ] || [ "$OSTYPE" == "msys" ]
then
    echo "Killing useless processes..."

    for process_name in "${windows_useless_processes[@]}"
    do
        pid=$(ps -W -s | awk "{ if (index(tolower(\$0), tolower(\"$process_name\")) != 0) { print \$1 } }")
        process_extra_info=""

        if [ ! -z "$pid" ]
        then
            taskkill //pid $pid //f //t &> /dev/null

            # confirm if process is really dead (better than using taskkill terrible output)
            info=$(ps -W -s | grep $pid)

            if [ -z "$info" ]
            then
                icon_process_status=$icon_process_closed
                process_extra_info="(pid: $pid)"
            else
                icon_process_status=$icon_process_close_error
            fi
        else
            icon_process_status=$icon_process_already_closed
        fi

        echo "$icon_process_status $process_name $process_extra_info"
    done
else
    echo "OS '$OSTYPE' not supported."
fi

