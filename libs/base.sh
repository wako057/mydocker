###########################
# General functions
###########################

ask () {
    # Ask a question to the user
    # :flag: --open  Use this flag to disable answer checking (facultative)
    # :param:        The question to be asked
    # :param:        Default answer
    # :params:       Possible answers. Ignored if flag --open is used (facultative)

    local question default_answer answer_list_array raw_answer_list answer_list answer open_question=false

    if [ "$1" = "--open" ]; then
        open_question=true
        shift
    fi
    question="$1"
    shift
    default_answer="$1"
    shift
    answer_list_array=( "$@" )
    raw_answer_list=${answer_list_array[*]}
    # Disable SC2001 because this is complex sed expression
    # https://github.com/koalaman/shellcheck/wiki/SC2001#exceptions
    # shellcheck disable=SC2001
    answer_list='^('$default_answer'|'$(echo "$raw_answer_list" | sed -e 's/ /|/g')')$'

    if [ "$USE_DEFAULTS_ANSWERS" = "1" ]; then
        echo "$default_answer"
        exit
    fi

    while true; do
        echo -ne "$question" 1>&2
        read -r answer
        if [ -z "$answer" ]; then
            log debug "User choosed default answer : $default_answer"
            echo "$default_answer"
            return 0
        elif $open_question || echo "$answer" | grep -qE "$answer_list"; then
            log debug "User choosed $answer"
            echo "$answer"
            return 0
        else
            echo -e "${RED}Answer $answer is not in the allowed list. Valid values :$EOC" 1>&2
            echo "${raw_answer_list/ /\n}" 1>&2
            echo 1>&2
        fi
    done
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "yes"
            return 0
        fi
    }
    echo "no"
    return 1
}

in_array () {
    # Test if array contains the specified element
    # :param: element to search
    # :param: array to search in
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}


log () {
    # Display log messages
    # :param: Log level : error, info or debug
    # :param: Message
    local now delta RED YELLOW GREEN CYAN EOC
    RED="\e[31m"
    YELLOW="\e[33m"
    GREEN="\e[32m"
    CYAN="\e[36m"
    EOC="\e[0m"

    if [ "$1" != "debug" ] || { [ "$1" = "debug" ] && [ "$DC_DEBUG" = 1 ];}; then
        case "$1" in
            error)
                prefix="$RED Error : "
            ;;
            warn)
                prefix="$YELLOW Warn : "
            ;;
            info)
                prefix="$CYAN Info : "
            ;;
            debug)
                prefix="$GREEN Debug : "
            ;;
            *)
                prefix=""
            ;;
        esac

        if [ "$DC_PERFTRACE" = 1 ]; then
            now=$(date "+%s%N" |cut -b1-13)
            delta=$((now-LAST_LOG_TIME))
            LAST_LOG_TIME="$now"
            printf "%-10s$SHLVL$prefix$EOC%s\n" "$delta" "$2" 1>&2
        else
            printf "%s$SHLVL$prefix%s$EOC%s\n" "$(date +'%Y/%m/%d %H:%M:%S')" "$2" 1>&2
        fi
    fi
}

get_current_dir () {
    # Determine directory for current script
    HERE="$( cd "$( dirname "$0" )" >/dev/null && pwd )"
    echo $HERE
}
