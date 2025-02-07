#!/usr/bin/env sh

RUN_CREATE=

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-c] [-h] parent name"
    _msg "  parent  parent dataset"
    _msg "  name    jail name"
    _msg "  -c      create datasets"
    _msg "          (properties are adjusted in any case)"
    _msg "  -h      show this help and exit"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":ch" OPT "$@"; do
    case $OPT in
        c)  RUN_CREATE=1                            ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done
shift $(( OPTIND - 1 ))

PARENT="$1"; shift
NAME="$1"; shift

# validate input
[ -z "$PARENT" ] && _usage "parent dataset missing"
[ -z "$NAME" ] && _usage "jail name missing"

_ds_type() {
    [ "$(/sbin/zfs get -Ho value type "$1" 2> /dev/null)" != "filesystem" ] \
        && return 1
    return 0
}
_ds_action() {
    PART="$1"; shift
    [ $RUN_CREATE ] && {
        _ds_type "$PART" && _fatal "err" "[$PART]" "already exists"

        _msg "gen" "[$PART]"
        /sbin/zfs create "$PART" || _fatal "err" "[$PART]" "create issue"
    }

    ! _ds_type "$PART" && _fatal "err" "[$PART]" "does not exist"
    for ATTR in "$@"; do
        _msg "set" "[$PART]" "value" "[$ATTR]"
        /sbin/zfs set "$ATTR" "$PART" || _fatal "err" "[$PART]" "set issue"
    done
}

! _ds_type "$PARENT" \
    && _fatal "parent" "$PARENT" "not available"

TARGET="$PARENT/$NAME"
_msg "using target" "$TARGET"

_ds_action "$TARGET"
_ds_action "$TARGET/usr" "canmount=off"
_ds_action "$TARGET/usr/home"
_ds_action "$TARGET/usr/local"
_ds_action "$TARGET/usr/obj"
_ds_action "$TARGET/usr/ports" "setuid=off"
_ds_action "$TARGET/usr/src"
_ds_action "$TARGET/var" "canmount=off"
_ds_action "$TARGET/var/audit" "setuid=off" "exec=off"
_ds_action "$TARGET/var/crash" "setuid=off" "exec=off"
_ds_action "$TARGET/var/db"
_ds_action "$TARGET/var/log" "setuid=off" "exec=off"
_ds_action "$TARGET/var/mail" "atime=on"
_ds_action "$TARGET/var/tmp" "setuid=off"

