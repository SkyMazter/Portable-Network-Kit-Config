#include <cstdlib>
#include <iostream>
using namespace std;

void getDockerStat() {
  cout << "Getting Docker Status" << endl;
  int returnCode = system("docker ps");

  if (returnCode == 256) {
    std::cout << "Docker does not seem to be running." << std::endl;
  } else {
    std::cout << "Command failed with return code: " << returnCode << std::endl;
  }
}

int main() {
  getDockerStat();
  return 0;
}
