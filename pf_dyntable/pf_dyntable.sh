#!/usr/bin/env sh

INTERFACE=${INTERFACE:-""}
TABLE_IP4=${TABLE_IP4:-"tbl_ip_ext4"}
TABLE_IP6=${TABLE_IP6:-"tbl_ip_ext6"}

# output
_msg() { >&2 echo "$*"; }
_log() { /usr/bin/logger "$0: $*"; }
_fatal() { _log "$*"; _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-4 table] [-6 table] [-i name] [-h] act"
    _msg "  -4  table name for IPv4 address"
    _msg "  -6  table name for IPv6 address"
    _msg "  -h  show this help and quit"
    _msg "  -i  interface name"
    _msg " act  command to run (run|show|flush)"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":4:6:i:h" OPT "$@"; do
    case $OPT in
        4) TABLE_IP4="$OPTARG"                  ;;
        6) TABLE_IP6="$OPTARG"                  ;;
        i) INTERFACE="$OPTARG"                  ;;
        h)  _usage                              ;;
        :)  _usage "-$OPTARG needs an argument" ;;
        \?) _usage "invalid option: -$OPTARG"   ;;
    esac
done
shift $(( OPTIND - 1 ))

ACTION="$1"
[ ! -e "/dev/pf" ] && _fatal "pf is not available"
[ -z "$ACTION" ] && _usage "action missing"
[ -z "$INTERFACE" ] && _usage "please specify interface"

# get raw interface information
! IF_INFO=$(/sbin/ifconfig "$INTERFACE") && _fatal "unknown interface name"

# parse and return ifconfig output
_info() {
    echo "$IF_INFO" | /usr/bin/grep -e "$1" | \
        /usr/bin/head -1 | /usr/bin/cut -d' ' -f2
}

# operate on pf table
_table() {
    TBL=$1; shift
    _log "table $TBL action $*"
    /sbin/pfctl -t "$TBL" -T "$@"
}


ADDR_IP4=$(_info "inet[^6]")
ADDR_IP6=$(_info "inet6\ [^f].*temporary")

# display current information
show() {
    echo "IPv4 interface:   $ADDR_IP4"
    echo "IPv6 interface:   $ADDR_IP6"
    echo "IPv4 pf table:    $(_table "$TABLE_IP4" "show" | /usr/bin/xargs)"
    echo "IPv6 pf table:    $(_table "$TABLE_IP6" "show" | /usr/bin/xargs)"
}

# flush table entries
flush() {
    _table "$TABLE_IP4" "flush"
    _table "$TABLE_IP6" "flush"
}

# set table entries
run() {
    _table "$TABLE_IP4" "replace" "$ADDR_IP4"
    _table "$TABLE_IP6" "replace" "$ADDR_IP6"
}

# parse action and invoke corresponding function
case $ACTION in
    [rR][uU][nN])           run     ;;
    [sS][hH][oO][wW])       show    ;;
    [fF][lL][uU][sS][hH])   flush   ;;
    *)  _usage "unknown command"    ;;
esac

exit 0
