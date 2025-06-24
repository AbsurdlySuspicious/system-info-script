#!/bin/bash

declare -A commands_present

check_cmd() {
    if which "$1"; then
        commands_present[$1]=1
    else
        echo "No '$1' command present"
    fi
}

cmd_present() {
    [[ ${commands_present[$1]} == 1 ]]
}

cmd_disable() {
    commands_present[$1]=0
}

_sudo() {
    if ! cmd_present sudo; then
        "$@"
    else
        sudo "$@"
    fi
}

run_ex() {
    local with_sudo=0 orig_cmd=("$@")
    if [[ $1 == sudo ]]; then
        shift 1
        with_sudo=1
    fi
    if cmd_present "$1"; then
        if [[ $with_sudo == 1 ]]; then
            _sudo "$@"
        else
            "$@"
        fi
    else
        echo "Command '$1' missing, skipping command: ${orig_cmd[*]}"
    fi
}

char_rep() {
    printf "%${2}s" | tr ' ' "$1"
}

heading() {
    local str="| $* |"
    local len=$(wc -m <<<"$str")
    local fill=$(char_rep '-' "$((len - 1))")
    echo -e "\n$fill\n$str\n$fill"
}

yesno() {
    "$@"; yn_code=$?
    if [[ $yn_code == 0 ]]; then
        yn_out="Yes"
    else
        yn_out="No ($yn_code)"
    fi
    echo "$yn_out"
}

heading Command test
check_cmd systemd-detect-virt
check_cmd inxi
check_cmd sudo
check_cmd pstree

heading Current environment
echo "Current user      : $(id)"
echo "Working directory : $(pwd)"

if ! cmd_present sudo; then
    echo "sudo is missing, running all commands as current user"
else
    heading Sudo test
    if ! _sudo id; then
        echo "Sudo doesn't work, running all commands as current user"
        cmd_disable sudo
    fi
fi

# heading Environment variables; env

heading OS and Kernel
lsb_release -a
uname -a
echo -n "CMDLINE: "; cat /proc/cmdline

heading Inxi
run_ex sudo inxi -CmDSG -c 0

heading Memory total
free -h

heading 'Block devices'; lsblk
heading 'FS: sizes'; df -h
heading 'FS: mounts'; findmnt

heading Detect virt
echo "Chroot  : $(yesno run_ex sudo systemd-detect-virt --chroot)"
echo "User NS : $(yesno run_ex sudo systemd-detect-virt --private-users)"
echo "Virt    : $(run_ex sudo systemd-detect-virt)"
echo "CVM     : $(run_ex sudo systemd-detect-virt --cvm)"

heading 'Cpuinfo (first processor)'
perl -pe '/^$/ && do {print; exit}' </proc/cpuinfo
perl -ne 'eof() && do {print "Last processor #: $1\n"; exit}; /processor\s*:\s*(\d+)/' </proc/cpuinfo

heading Processes
pstree

heading Finished
