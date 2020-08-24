#!/bin/bash
set -e

# try to use perl
command -v perl >/dev/null && exec perl -e '
use strict;
use warnings;
use Time::HiRes qw(usleep);

my $t2 = 0;
my $slp = 10;
for (;;) {
	usleep(15000);
	my $t = time();
	if ($t==$t2) {next}
	
	$t2 = $t;
	my $c = $t%7;
	printf "\033[H\033[1;37;4%dm\033[J\n  %d\n",$c,$t;
	usleep(1000*$slp);
	$slp = 800;
}'

# fallback to bash
sd=0.01
while ! read -t0.015; do
	t=$(date +%s)
	[ $t = "$t2" ] &&
		continue
	
	t2=$t
	c=$((t%7))
	printf "\033[H\033[1;37;4${c}m\033[J\n  $t\n"
	read -t$sd || true
	sd=0.8
done
