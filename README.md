
Git-based History Hook for Taskwarrior
======================================

Keeping taskwarrior's data under version control grants various advantages,
including a detailed change history and of course synchronization capabilities.
There are several scripts which aim to provide that functionality but most of
them have some little drawbacks. For example, [taskgit][], [task-git.sh][] and
[gtw][] are implemented as wrapper scripts which imply either aliasing or using
an unfamiliar command. On the other hand, [on-exit_git.py][] already exploits
taskwarrior's hook capabilities but does not provide useful commit messages
while maintaining redundant data. This approach also uses taskwarrior's hook
mechanism but maintains the data in a more clever manner.

[taskgit]:        https://gist.github.com/Unode/9366218              "taskgit (Gist)"
[task-git.sh]:    https://github.com/kostajh/task-git                "task-git"
[gtw]:            https://github.com/hoxu/gtw                        "gtw"
[on-exit_git.py]: https://gist.github.com/wbsch/fe5d0f392657fdfa6fe4 "on-exit_git.py (Gist)"


Concept
-------

Instead of tracking all data files only the `pending.data` file is kept under
version control. The idea is to generate the required information for the
`backlog.data`, `completed.data` and `undo.data` files from the commit history.
For example, the `completed.data` file contains all *deleted* and *completed*
entries which are moved from the `pending.data` file each time the garbage
collection is invoked [[1][]]. This appears as deletion in the commit history
and thus can easily appended to the unsynced `completed.data` file on a remote
computer. As mentioned, this can be done for the other two files in a similar
way. By means of the `post-merge` git hook these three files can be updated
automatically.

[1]: http://taskwarrior.org/docs/ids.html "ID Numbers"

### Advantages

*	The repository can be kept at a minimum size since all information are given
	by the commit history
*	Changes in the history of the `pending.data` file can be projected directly
	onto the other files

### Drawbacks

*	If the format of any file changes the generation procedure is likely to
	break
*	Updating the data files after a large git update can be time consuming

