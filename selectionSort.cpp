#include <iostream>
using namespace std;

void selectionSort(int list[], int len) {
  int i;
  int smallestIndex;
  int loc;
  int temp;
  for (i = 0; i < len - 1; i++) {
    smallestIndex = i;

    for (loc = i + 1; loc < len; loc++)
      if (list[loc] < list[smallestIndex])
        smallestIndex = loc;
    temp = list[smallestIndex];
    list[smallestIndex] = list[i];
    list[i] = temp;
  }
}

void printArray(int *list) {
  int i;
  for (i = 0; i < 10; i++)
    cout << list[i] << " ";
  cout << endl;
}

int main() {
  int list[] = {252, 456, 34, 25, 73, 46, 89, 10, 5, 16};
  cout << "Before sorting:" << endl;
  printArray(list);
  selectionSort(list, 10);
  cout << "After sorting:" << endl;
  printArray(list);
  return 0;
}
