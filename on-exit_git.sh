#! /usr/bin/env bash
#
# Call configurations:
#
# | Repository | Input | Action                                   |
# |------------|-------|------------------------------------------|
# |   dirty    |   +   | add/modify/start/stop/done               |
# |   dirty    |   0   | garbage collection moved completed tasks |
# |   clean    |   0   | just informative usage                   |
# |   clean    |   +   | ?                                        |
#

# Ensure that task hooks are not invoked by the hook again
TASK=`which task`
task() { "$TASK" rc.hooks=off "$@"; }


# Remove argument prefixes
TASK_API=${1#api:}
TASK_ARGS=( ${2#args:} )
TASK_COMMAND=${3#command:}
TASK_RC=${4#rc:}
TASK_DATA=${5#data:}
TASK_VERSION=${6#version:}

# Fetch all touched tasks
entries=()
while read entry; do
	entries+=( "$entry" )
done


# Exit if no repository present
[ -d "$TASK_DATA/.git" ] || exit 0

# Set GIT_DIR and GIT_WORK_TREE to be independent of PWD
export GIT_DIR="$TASK_DATA/.git"
export GIT_WORK_TREE="$TASK_DATA"


# Exit if no change was made
git diff --quiet --exit-code && exit 0


# Generate reasonable commit message
message=""
if [ ${#entries[@]} -gt 0 ]; then
	message+="Updated ${#entries[@]} task"
	[ ${#entries[@]} -ne 1 ] && message+="s"
	message+=": $TASK_COMMAND\n"
	for entry in "${entries[@]}"; do
		uuid=$(grep -oP '"uuid"\s*:\s*"\K[0-9a-fA-F-]{36}(?=")' <<< "$entry")
		message+="\n* $uuid"
	done
else
	uuids=( $(git diff -U0 -- pending.data | grep '^-\[.\+\]$' | grep -oP 'uuid:"\K[0-9a-fA-F-]{36}(?=")') )
	message+="Updated ${#uuids[@]} task"
	[ ${#uuids[@]} -ne 1 ] && message+="s"
	message+=": GC\n"
	for uuid in "${uuids[@]}"; do
		message+="\n* $uuid"
	done
fi

git add pending.data
echo -e "$message" | git commit --quiet -F -

