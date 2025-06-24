#!/bin/bash

check_cmd() {
    which "$1" || echo "No $1"
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


heading Sudo/user test
id
sudo id

heading OS and Kernel
lsb_release -a
uname -a
echo -n "CMDLINE: "; cat /proc/cmdline

heading Inxi
sudo inxi -CmDSG -c 0

heading Memory total
free -h

heading 'Block devices'; lsblk
heading 'FS: sizes'; df -h
heading 'FS: mounts'; findmnt

heading Detect virt
echo "Chroot  : $(yesno sudo systemd-detect-virt --chroot)"
echo "User NS : $(yesno sudo systemd-detect-virt --private-users)"
echo "Virt    : $(sudo systemd-detect-virt)"
echo "CVM     : $(sudo systemd-detect-virt --cvm)"

heading 'Cpuinfo (first processor)'
perl -pe '/^$/ && do {print; exit}' </proc/cpuinfo
perl -ne 'eof() && do {print "Last processor #: $1\n"; exit}; /processor\s*:\s*(\d+)/' </proc/cpuinfo

heading Processes
pstree

heading Finished
