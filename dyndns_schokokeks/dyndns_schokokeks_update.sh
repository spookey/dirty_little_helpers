#!/usr/bin/env sh

BIN_CURL=${BIN_CURL:="/usr/local/bin/curl"}
BIN_DNSQ=${BIN_DNSQ:="/usr/bin/drill"}

ADDR_URL=${ADDR_URL:="https://ip.schokokeks.org"}
ADDR_NS1=${ADDR_NS1:="ns1.schokokeks-dns.de"}
ADDR_NS2=${ADDR_NS2:="ns2.schokokeks-dns.de"}
ADDR_NS3=${ADDR_NS3:="ns3.schokokeks-dns.de"}

KEY_FILE=${KEY_FILE:="$HOME/.ssh/id_rsa"}
SSH_DDNS=${SSH_DDNS:="dyndns@zucker.schokokeks.org"}
CUST_DNS=""

_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }
_usage() {
    _msg "usage: $0 [-d] [-n] [-k] [-h] addr"
    _msg "  -d  dyndns ssh host connection"
    _msg "  -n  use custom dns server"
    _msg "  -k  path to ssh key file"
    _msg "  -h  show this help and quit"
    _msg "addr  dyndns address entry"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

while getopts ":d:n:k:h" OPT "$@"; do
    case $OPT in
        d)  SSH_DDNS="$OPTARG"                  ;;
        n)  CUST_DNS="$OPTARG"                  ;;
        k)  KEY_FILE="$OPTARG"                  ;;
        h)  _usage                              ;;
        :)  _usage "-$OPTARG needs an argument" ;;
        \?) _usage "invalid option: -$OPTARG"   ;;
    esac
done
shift $(( OPTIND - 1 ))

ADDRESS="$1"

[ -z "$ADDRESS" ] && _fatal "please specify address"


_nameserver() {
    if [ -n "$CUST_DNS" ]; then
        echo "$CUST_DNS"
    else
        {
            echo "$ADDR_NS1"
            echo "$ADDR_NS2"
            echo "$ADDR_NS3"
        } | /usr/bin/sort -R | /usr/bin/head -1
    fi
}
_d_query() {
    $BIN_DNSQ "$1" "@$2" "$ADDRESS" |\
        /usr/bin/grep ';; ANSWER' -1 | /usr/bin/xargs |\
            /usr/bin/cut -d' ' -f8
}
_h_query() {
    $BIN_CURL -sL "$1" "$ADDR_URL" | /usr/bin/xargs
}
_update() {
    >&2 /usr/bin/ssh "$1" -T -i "$KEY_FILE" "$SSH_DDNS"
}

_msg "++" "[$(/bin/date +%s)] $(/bin/date)"
_msg "--" "dyndns host: $SSH_DDNS"
_msg "--" "key file:    $KEY_FILE"

NSERVER=$(_nameserver)
_msg "--" "nameserver:  $NSERVER"
_msg


_run() {
    DNSQ=$(_d_query "$2" "$NSERVER")
    _msg "$1" "dns:         $DNSQ"

    if [ -n "$DNSQ" ]; then
        HTTP=$(_h_query "$1")
        _msg "$1" "http:        $HTTP"

        if [ "$DNSQ" != "$HTTP" ]; then
            _msg "$1" "updating..."
            _update "$1"
        else
            _msg "$1" "no changes"
        fi
    fi
    _msg
}

_run "-6" "aaaa"
_run "-4" "a"

exit 0
