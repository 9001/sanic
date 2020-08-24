#!/bin/bash
set -e
clear

# try to use perl
command -v perl >/dev/null && exec perl -e '
use strict;
use warnings;
use Time::HiRes qw(usleep gettimeofday);

for (;;) {
	usleep(15000);
	my ($sec, $usec) = gettimeofday();
	printf "%d\n%10d\033[H", $sec, $usec/1000
}'

# fallback to bash
while true; do
	read -t0.015 || true
	date +%s$'\n       '%N
	printf '\033[H'
done
