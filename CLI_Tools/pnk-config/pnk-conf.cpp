#include <cstddef>
#include <cstdio>
#include <iostream>
#include <regex>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

using namespace std;

string runScript(const vector<string> &args)
{
  int pipefd[2];
  pipe(pipefd); // pipefd[0] = read, pipefd[1] = write
  pid_t pid = fork();

  if (pid == 0)
  {
    close(pipefd[0]);

    dup2(pipefd[1], STDOUT_FILENO);
    close(pipefd[1]);

    std::vector<char *> cargs;
    for (const auto &arg : args)
    {
      cargs.push_back(const_cast<char *>(arg.c_str()));
    }
    cargs.push_back(NULL);
    execvp(cargs[0], cargs.data());
    perror("unable to execute command");
    _exit(127);
  }
  else
  {
    close(pipefd[1]);
    string output;
    char buffer[1024];
    ssize_t count;

    while ((count = read(pipefd[0], buffer, sizeof(buffer))) > 0)
    {
      output.append(buffer, count);
    }

    return "Captured: \n" + output;
    close(pipefd[0]);
  }
  return "There was an Error executing the command...";
}

bool isDockerInstalled()
{
  pid_t pid = fork();
  if (pid == 0)
  {
    execlp("docker", "docker", "--version", NULL);
    _exit(127);
  }
  else
  {
    int status;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status))
    {
      int exitCode = WEXITSTATUS(status);
      return exitCode == 0; // return true
    }
  }
  return false;
}

bool isContainerRunning(string container_name)
{
  int pipefd[2];
  pipe(pipefd); // pipefd[0] = read, pipefd[1] = write

  pid_t pid = fork();

  string arg_container_name = "name=" + container_name;
  const char *c_container_name = arg_container_name.c_str();
  const char *args[] = {(char *)c_container_name};

  if (pid == 0)
  {
    close(pipefd[0]);

    dup2(pipefd[1], STDOUT_FILENO);
    close(pipefd[1]);

    execlp("docker", "container", "ps", "--filter", c_container_name, NULL);

    perror("unable to run docker command");
    _exit(127);
  }
  else
  {
    close(pipefd[1]);

    string output;
    ssize_t count;
    char buffer[1024];

    while ((count = read(pipefd[0], buffer, sizeof(buffer))) > 0)
    {
      output.append(buffer, count);
    }

    regex pattern("\\b" + container_name + "\\b");
    bool isActive = regex_search(output, pattern);
    return isActive;
  }

  return false;
}

int main()
{

  if (!isDockerInstalled())
  {
    cout << "Docker is not installed!, Would you like to install docker?"
            "(y/N): ";
    char ans;
    cin >> ans;
    if (ans == 'y')
    {
      cout << runScript({"bash", "./dummy.sh"}) << endl;
    }
    else
    {
      cout << "Closing Script..." << endl;
      return 0;
    }
  }

  cout << "Docker is installed! Proceeding to next check..." << endl;

  const vector<string> container_names = {"dummy", "dummy", "dummy"};

  for_each(container_names.begin(), container_names.end(), [](string container_name)
           {
             bool container_status = isContainerRunning(container_name);
             if (!container_status)
             {
               cout << "The " + container_name + " container is not running...\n"
                    << "Would you like to run the installation script? (y/N): ";
               char ans;
               cin >> ans;
               if (ans == 'y')
               {
                 cout << runScript({"bash", "./" + container_name + "_installation.sh"}) << endl;
               }
               else
               {
                 cout << "Skipping Installation Script..." << endl;
                 exit;
               }
             }
           });

  return 0;
}
