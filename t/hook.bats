#! /usr/bin/env bats

# Tests whether the commit count is equal to the given number. Note, that the
# initial commit is not counted, i.e. the given number has to be count-1.
commit_count_eq() {
	run git log --oneline
	[ $status -eq 0 ]
	[ ${#lines[@]} -eq $(($1+1)) ]
}

# Tests if the commit subject matches the given regex. The optional second
# argument denotes the zero-based index of the commit oneliners in reverse
# chronological order (0 by default).
commit_subject_eq() {
	run git log --oneline
	[ $status -eq 0 ]
	echo -e "$output"
	grep -qP "$1" <<< "${lines[${2:-0}]}"
}

# Tests wheather a commit has exactly m=$1 additions and n=$2 deletions. An
# optional third argument can specify the commit to be examined.
commit_numstat_eq() {
	run git diff --numstat ${3:-HEAD}^ ${3:-HEAD}
	[ $status -eq 0 ]
	grep -qP "^$1\s+$2\s+pending.data$" <<< "$output"
}

# Tests wheather a particular line of the commit patch matches the given regex.
# The optional second argument denotes the line index (-1 by default) while the
# optional third argument can specify the commit to be examined.
commit_patch_eq() {
	run git diff -U0 ${3:-HEAD}^ ${3:-HEAD}
	[ $status -eq 0 ]
	grep -qP "$1" <<< "${lines[${2:--1}]}"
}


# Sets up a temporary task data directory, initializes the git repository and
# symlinks the task hook to be tested.
setup() {
	export TASKDATA=$(mktemp -d)
	touch "$TASKDATA/pending.data"
	cd "$TASKDATA"
	git init
	git add "pending.data"
	git commit -m "Initial commit"
	mkdir "$TASKDATA/hooks"
	ln -s "$BATS_TEST_DIRNAME/../on-exit_git.sh" "$TASKDATA/hooks"
}

@test "Commit task addition " {
	task add "Test Task 1"

	commit_count_eq 1
	commit_subject_eq '\badd\b'
	commit_numstat_eq 1 0
	commit_patch_eq '"Test Task 1"'
}

@test "Commit task modification" {
	task add "Test Task 2"
	task 1 modify pro:Test

	commit_count_eq 2
	commit_subject_eq '\bmodify\b'
	commit_numstat_eq 1 1
	commit_patch_eq '^-' -2
	commit_patch_eq '^\+'
}

@test "Commit task start/stop/done" {
	task add "Test Task 3"
	task 1 start
	task 1 stop
	task 1 done

	commit_count_eq 4
	commit_subject_eq '\bstart\b' 2
	commit_subject_eq '\bstop\b'  1
	commit_subject_eq '\bdone\b'
	commit_numstat_eq 1 1

	# Run garbage collection (cf. http://taskwarrior.org/docs/ids.html)
	task completed

	commit_count_eq 5
	commit_subject_eq '\bGC\b'
	commit_numstat_eq 0 1
}

@test "Commit task deletion" {
	task add "Test Task 4"
	task rc.confirmation=off 1 delete

	commit_count_eq 2
	commit_subject_eq '\bdelete\b'
	commit_numstat_eq 1 1

	# Run garbage collection (cf. http://taskwarrior.org/docs/ids.html)
	task all

	commit_count_eq 3
	commit_subject_eq '\bGC\b'
	commit_numstat_eq 0 1
}

# TODO Test completion/deletion of multiple tasks at once

# Removes the temporary task data directory.
teardown() {
	cd "$OLDPWD"
	echo "Removing $TASKDATA"
	rm -rf "$TASKDATA"
}

