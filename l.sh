#! /bin/bash
clear
lxc delete u2-1vcpu-128mb -f
lxc launch ubuntu:20.04 u2-1vcpu-128mb -p dev1
lxc exec u2-1vcpu-128mb -- free -mh
lxc exec u2-1vcpu-128mb -- df -h
lxc exec u2-1vcpu-128mb bash
