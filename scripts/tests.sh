#!/usr/bin/env bash
# vim: et ts=4 sw=4

set -e

if [ -z "$1" ]; then
    echo "USAGE: $0 cpu-b084-sp17"
    exit 1
fi

function green {
    printf "\e[32m"
}

function normal {
    printf "\e[0m"
}

function red {
    printf "\e[31m"
}

if ! ping -q -c 1 $1 > /dev/null; then
    echo "Host $1 may be down. Ping test failed"
    exit 1
fi

green; echo "Host is up..."; normal

# Check that telnetd isn't running at all
printf "Checking that telnet doesn't exist..."
if echo -e "\x1dclose\x0d" | telnet $1 > /dev/null 2>&1; then
    red; echo "Telnet IS available! Test failed"; normal
    exit 1
fi
green; echo "PASS"; normal

USERS="laci flaci acctf spear"

# Check that the users exist in the first place
printf "Checking for $USERS..."
for user in $USERS; do
    if ! ssh -o PasswordAuthentication=no $user@$1 "exit" > /dev/null 2>&1; then
        red; echo "User $user does NOT exist passwordless!"; normal
        exit 1
    fi
done
green; echo "PASS"; normal

# Check for matching ID/GID
function check_uid_gid {
    printf "Checking that $2 has UID $3 and GID $4..."
    _R=$(ssh -o PasswordAuthentication=no $2@$1 "echo USER=\$(id -u):\$(id -g)" 2> /dev/null)
    P="USER=(.+):(.+)"
    if [[ $_R =~ $P ]]; then
        if [ "${BASH_REMATCH[1]}" != "$3" ]; then
            red; echo "UID ${BASH_REMATCH[1]} does not match $3"; normal
            exit 1
        fi
        if [ "${BASH_REMATCH[2]}" != "$4" ]; then
            red; echo "GID ${BASH_REMATCH[2]} does not match $4"; normal
            exit 1
        fi
    else
        red; echo "No match found in $_R"; normal
        exit 1
    fi
    green; echo "PASS"; normal
}

check_uid_gid $1 laci 8412 2211
check_uid_gid $1 flaci 11121 2376
check_uid_gid $1 acctf 11846 2459
check_uid_gid $1 spear 7753 1080

# Check that chrt works passwordless
printf "Checking for passwordless chrt..."
for user in $USERS; do
    if ! ssh -o PasswordAuthentication=no $user@$1 "chrt -r 4 sleep 1" > /dev/null 2>&1; then
        red; echo "User $user cannot exec chrt passwordless!"; normal
        exit 1
    fi
done
green; echo "PASS"; normal

# Check that sudo works passwordless
printf "Checking for passwordless sudo with chrt..."
for user in $USERS; do
    if ! ssh -o PasswordAuthentication=no $user@$1 "sudo chrt -r 4 sleep 1" > /dev/null 2>&1; then
        red; echo "User $user cannot exec sudo passwordless!"; normal
        exit 1
    fi
done
green; echo "PASS"; normal

