#!/bin/sh

build_startup_command() {
    local cmd=""

    if [ "${WRITE_TRADES:-true}" = "true" ]; then
        cmd="$cmd --write-trades"
    fi

    if [ "${WRITE_FILLS:-true}" = "true" ]; then
        cmd="$cmd --write-fills"
    fi

    if [ "${WRITE_ORDER_STATUSES:-true}" = "true" ]; then
        cmd="$cmd --write-order-statuses"
    fi

    if [ "${WRITE_MISC_EVENTS:-true}" = "true" ]; then
        cmd="$cmd --write-misc-events"
    fi

    if [ "${SERVE_ETH_RPC:-true}" = "true" ]; then
        cmd="$cmd --serve-eth-rpc"
    fi

    if [ "${SERVE_INFO:-true}" = "true" ]; then
        cmd="$cmd --serve-info"
    fi

    cmd="$cmd --replica-cmds-style ${REPLICA_CMDS_STYLE:-actions}"

    echo "$cmd"
}

ARGS=$(build_startup_command)
exec /home/hluser/hl-visor run-non-validator $ARGS