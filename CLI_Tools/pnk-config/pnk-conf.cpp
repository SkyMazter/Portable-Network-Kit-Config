#include <cstddef>
#include <cstdio>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

using namespace std;

void getDockerStat() {
  int pipefd[2];
  pipe(pipefd); // pipefd[0] = read, pipefd[1] = write
  pid_t pid = fork();

  if (pid == 0) {
    close(pipefd[0]); // close unused read end

    // Redirect stdout to pipe
    dup2(pipefd[1], STDOUT_FILENO);
    close(pipefd[1]);

    execlp("docker", "docker", "ps", NULL);

    perror("unable to execure command");
    _exit(1);
  } else if (pid > 0) {
    cout << "This is the parent process\n";

    close(pipefd[1]); // close unused write end

    string output;
    char buffer[1024];
    ssize_t count;

    // Read child output
    while ((count = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
      output.append(buffer, count);
    }

    cout << "Captured:\n" << output;

    close(pipefd[0]);
    waitpid(pid, NULL, 0); // wait for child
  } else {
    cerr << "Fork failed\n";
  }
}

int main() {
  getDockerStat();
  return 0;
}
