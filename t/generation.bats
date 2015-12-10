#! /usr/bin/env bats

load common


GENERATE=$(readlink -f "$BATS_TEST_DIRNAME/../generate.sh")

generate() {
	"$GENERATE" "$@"
}

diff_data() {
	diff "$TASKDATA/$1.data" <(generate "$1")
}


@test "Generate completed.data file (simple)" {
	task add "Test Task 1"
	task 1 done

	diff_data completed

	task completed

	diff_data completed
}

@test "Generate backlog.data file (simple)" {
	task add "Test Task 2"
	task 1 done

	diff_data backlog

	task completed

	diff_data backlog
}

@test "Generate undo.data file (simple)" {
	task add "Test Task 3"
	task 1 done

	diff_data undo

	task completed

	diff_data undo
}


@test "Generate completed.data file (multiple)" {
	task add "Test Task 4"
	task add "Test Task 5"
	task 1,2 done

	diff_data completed

	task completed

	diff_data completed
}

@test "Generate backlog.data file (annotations)" {
	task add "Test Task 6"
	task 1 annotate "Test Annotation 1"

	diff_data backlog
}

@test "Generate undo.data file (annotations)" {
	task add "Test Task 7"
	task 1 annotate "Test Annotation 2"

	diff_data undo
}

