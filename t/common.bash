#! /usr/bin/env bats

# Sets up a temporary task data directory, initializes the git repository and
# symlinks the task hook to be tested. Also changes the PWD to the temporary
# data directory.
setup() {
	export TASKDATA=$(mktemp -d)
	touch "$TASKDATA/pending.data"
	cd "$TASKDATA"
	git init
	git add "pending.data"
	git commit -m "Initial commit"
	mkdir "$TASKDATA/hooks"
	local base="${BATS_TEST_DIRNAME:-$(dirname "$BASH_SOURCE")}/.."
	ln -s "$(readlink -f "$base")/on-exit_git.sh" "$TASKDATA/hooks"
}

# Removes the temporary task data directory.
teardown() {
	cd "$OLDPWD"
	echo "Removing $TASKDATA"
	rm -rf "$TASKDATA"
}

