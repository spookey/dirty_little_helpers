#!/usr/bin/env sh

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

USERNAME="${USERNAME:-"$(/usr/bin/id -un)"}"
BASE_RUN=
CONTINUE=

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-U username] [-b] [-c] [-h] cmd"
    _msg "  -U  user in jail - default is $USERNAME"
    _msg "  -b  also run command on base host (-U has no effect)"
    _msg "  -c  do not stop on failed command"
    _msg "  -h  show this help and quit"
    _msg "cmd   command to run"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":U:bch" OPT "$@"; do
    case $OPT in
        U)  USERNAME="$OPTARG"                  ;;
        b)  BASE_RUN=1                          ;;
        c)  CONTINUE=1                          ;;
        h)  _usage                              ;;
        :)  _usage "-$OPTARG needs an argument" ;;
        \?) _usage "invalid option: -$OPTARG"   ;;
    esac
done
shift $(( OPTIND - 1 ))

[ -z "$*" ] && _fatal "command missing"

_launch() {
    NAME=$1; shift
    _msg "###"
    _msg "# $NAME"
    "$@"
    CODE=$?
    _msg "# $NAME $CODE"
    _msg "###";
    [ $CODE -ne 0 ] && [ ! $CONTINUE ] && {
        _fatal ">> $NAME error"
    }
}

[ $BASE_RUN ] && {
    _launch "base" "$@"
}
for NAME in $(/usr/sbin/jls -q name | /usr/bin/sort); do
    _launch "$NAME" /usr/sbin/jexec -U "$USERNAME" "$NAME" "$@"
done

exit 0
