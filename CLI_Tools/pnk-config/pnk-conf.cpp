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

string runCMD(const vector<string> &args)
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

    return "\nCaptured: \n" + output;
    close(pipefd[0]);
  }
  return "\nThere was an Error executing the command...";
}

void runScript(const vector<string> &args)
{
  pid_t pid = fork();

  if (pid == 0)
  {
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
    cout << "Script ran normally..." << endl;
    return;
  }
}

bool isDockerInstalled()
{
  pid_t pid = fork();
  if (pid == 0)
  {
    execlp("docker", "sudo"
                     "docker",
           "--version", NULL);
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
    bool is_active = regex_search(output, pattern);
    is_active ? cout << "\nThe container for " << container_name
                     << " is running normally..." << endl
              : cout << "\nThe " + container_name << " is not running..." << endl;

    return is_active;
  }

  return false;
}

void checkContainerStatus(const string container_name)
{
  const string dir = "/home/admin/Portable-Network-Kit-Config/Shell_Scripts/";
  const string script_name = container_name + "_installation.sh";
  bool container_status = isContainerRunning(container_name);

  if (container_status)
  {
    cout << "\nThe " + container_name + " is running normally, skipping to next container..." << endl;
    return;
  }
  regex pattern("\\b" + container_name + "\\b");
  const string shell_output = runCMD({"docker", "images", container_name, "--format", "{{.ID}}: {{.Repository}}"});

  bool is_installed = regex_search(shell_output, pattern);

  if (!is_installed)
  {
    cout << "\nThe image for " + container_name
         << " is not installed yet!, Would you like to run it's install script?"
            "(y/N): ";
    char ans;
    cin >> ans;
    if (ans == 'y')
    {

      runScript({"bash", dir + container_name + "_installation.sh"});
    }
    else
    {
      cout << "\nSkipping Installation Script..." << endl;
      return;
    }
  }

  cout << "\nVerifying the success of the install script..." << endl;
  container_status = isContainerRunning(container_name);
  if (!container_status)
  {

    cout << "\nThe container for " + container_name
         << " is not running yet!, Attempting to start is up manually...\n";
    cout << runCMD({"bash", dir + "start_container.sh", container_name})
         << endl;
  }

  return;
}

int main()
{
  const vector<string> container_names = {"wordpress", "matrix", "etherpad", "owncloud"};

  if (!isDockerInstalled())
  {
    cout << "Docker is not installed!, Would you like to install docker?"
            "(y/N): ";
    char ans;
    cin >> ans;
    if (ans == 'y')
    {
      cout << runCMD({"bash", "/home/admin/Portable-Network-Kit-Config/Shell_Scripts/docker_install.sh"}) << endl;
    }
    else
    {
      cout << "\nClosing Script..." << endl;
      return 0;
    }
  }

  cout << "\nDocker is installed! Proceeding to next check..." << endl;

  for_each(container_names.begin(), container_names.end(), checkContainerStatus);

  // CHECK FOR UNIFI CONTROLLER
  return 0;
}
