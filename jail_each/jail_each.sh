#!/usr/bin/env sh

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

USERNAME="${USERNAME:-"root"}"
CONTINUE=

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-U username] [-c] [-h] cmd"
    _msg "  -U  user from jailed environment - default is $USERNAME"
    _msg "  -c  do not stop on failed command"
    _msg "  -h  show this help and quit"
    _msg "cmd   command to run"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":U:ch" OPT "$@"; do
    case $OPT in
        U)  USERNAME="$OPTARG"                  ;;
        c)  CONTINUE=1                          ;;
        h)  _usage                              ;;
        :)  _usage "-$OPTARG needs an argument" ;;
        \?) _usage "invalid option: -$OPTARG"   ;;
    esac
done
shift $(( OPTIND - 1 ))

[ -z "$*" ] && _fatal "command missing"


for NAME in $(/usr/sbin/jls -q name | /usr/bin/sort); do
    _msg "###"
    _msg "# $NAME"
    /usr/sbin/jexec -U "$USERNAME" "$NAME" "$@"
    CODE=$?
    _msg "# $NAME $CODE"
    _msg "###";
    [ $CODE -ne 0 ] && [ ! $CONTINUE ] && {
        _fatal ">> $NAME error"
    }
done

exit 0
