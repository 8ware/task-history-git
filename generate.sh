#! /usr/bin/env bash
#
# Usage:
# generate
# generate [--date <date>] {completed|backlog|undo}
#
# Use either from within repository or setup environment variables, i.e.
# GIT_DIR and GIT_WORK_TREE=$(dirname "$GIT_DIR")
#
# TODO rename script to 'unpack'?
# TODO Make translation to JSON more robust (for_backlog)
# TODO Fix date usage!
#

warn () {
	echo "$@" >&2
}

die () {
	warn "$@"
	exit 1
}


generate_data() {
	local format=$1
	local date=$2

	# Only consider commits beginning with the second one since first one does
	# not have a predecessor (also the initial commit should not carry relevant
	# data, i.e. only initialization)
	local commits=( $(git log --reverse --after="$date" --pretty=format:%H pending.data | tail -n +2) )

	local commit numstat adds dels
	for commit in "${commits[@]}"; do
		numstat=$(git diff --numstat $commit^ $commit pending.data)
		adds=$(grep -oP '^\d+' <<< "$numstat")
		dels=$(grep -oP '^\d+\s+\K\d+' <<< "$numstat")
		$format $commit $adds $dels
	done
}

# Based on commits which contain deletions only
for_completed() {
	local commit=$1
	local adds=$2
	local dels=$3

	[ $adds -ne 0 ] && return

	git diff -U0 $commit^ $commit pending.data | tail -n $dels | cut -d - -f 2-
}

# Based on commits which contain at least an addition
for_undo() {
	local commit=$1
	local adds=$2
	local dels=$3

	[ $adds -eq 0 ] && return

	local IFS=$'\n'
	local patch=( $(git diff -U0 $commit^ $commit pending.data | tail -n $((adds+dels))) )

	if [ $dels -eq 0 ]; then
		local idx line
		for idx in $(seq ${#patch[@]}); do
			new=${patch[idx-1]}
			time=$(grep -oP 'modified:"\K\d+(?=")' <<< "$new")
			echo "time $time"
			echo "new ${new#+}"
			echo "---"
		done
	else
		local idx line
		for idx in $(seq 1 2 ${#patch[@]}); do
			old=${patch[idx-1]}
			new=${patch[idx]}
			time=$(grep -oP 'modified:"\K\d+(?=")' <<< "$new")
			echo "time $time"
			echo "old ${old#-}"
			echo "new ${new#+}"
			echo "---"
		done
	fi
}

# Based on additions only
for_backlog() {
	local commit=$1
	local adds=$2
	local dels=$3

	[ $adds -eq 0 ] && return

	git diff -U0 $commit^ $commit pending.data | grep -oP '^\+\K\[.+\]$' \
		| perl -MTime::Piece -pe 's/(?<!description:)"(\d+)"/localtime ($1-3600)->strftime("\"%Y%m%dT%H%M%SZ\"")/ge' \
		| perl -pe 's/" /",/g;' -e 's/(\w+):/"$1":/g;' -e 's/^\[/\{/;' -e 's/\]$/\}/'
}


# Use earliest date as default to include all commits
date='1970-01-01T00:00:00Z'
while true; do
	case "$1" in
		-d|--date)
			date=$2
			shift 2
			;;
		*)
			break
			;;
	esac
done

case "$1" in
	completed|backlog|undo)
		generate_data for_$1 "$date"
		;;
	*)
		die "Unknown command: $1"
		;;
esac

