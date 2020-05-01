#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

static void set_proc_name(char *new_name, char **argv)
{
	if (strcmp(argv[0], new_name) == 0)
		return;

	char exec_name[strlen(argv[0])+1];
	strcpy(exec_name, argv[0]);
	argv[0] = new_name;

	execv(exec_name, argv);
}

int main(int argc, char **argv)
{
	// set name to traind
	set_proc_name("traind", argv);

	// fork
	pid_t pid;
	while ((pid = fork()) == -1)
		usleep(10000);

	// child execs getty
	if (pid == 0) {
		execl("/sbin/agetty", "/sbin/agetty",
		      "-o", "-p -- \\u", "tty2", "linux", (char *)0);
		exit(1);
	}

	// parent waits	
	waitpid(pid, NULL, 0);
	for (;;)
		pause();
}
