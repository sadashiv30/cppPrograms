//************************************************************
// Author: D.S. Malik
//
// class cashRegister
// This class specifies the members to implement a cash
// register.
//************************************************************
class cashRegister {
public:
  int getCurrentBalance() const;
  // Function to show the current amount in the cash
  // register.
  // Postcondition: The value of cashOnHand is returned.
  void acceptAmount(int amountIn);
  // Function to receive the amount deposited by
  // the customer and update the amount in the register.
  // Postcondition: cashOnHand = cashOnHand + amountIn;
  cashRegister(int cashIn = 500);
  // Constructor
  // Sets the cash in the register to a specific amount.
  // Postcondition: cashOnHand = cashIn;
  // If no value is specified when the
  // object is declared, the default value
  // assigned to cashOnHand is 500.
private:
  int cashOnHand; // variable to store the cash
  // in the register
};
//************************************************************
// Author: D.S. Malik
//
// class dispenserType
// This class specifies the members to implement a dispenser.
//************************************************************
class dispenserType {
public:
  int getNoOfItems() const;
  // Function to show the number of items in the machine.
  // Postcondition: The value of numberOfItems is returned.

  int getCost() const;
  // Function to show the cost of the item.
  // Postcondition: The value of cost is returned.
  void makeSale();
  // Function to reduce the number of items by 1.
  // Postcondition: numberOfItems--;
  dispenserType(int setNoOfItems = 50, int setCost = 50);
  // Constructor
  // Sets the cost and number of items in the dispenser
  // to the values specified by the user.
  // Postcondition: numberOfItems = setNoOfItems;
  // cost = setCost;
  // If no value is specified for a
  // parameter, then its default value is
  // assigned to the corresponding member
  // variable.
private:
  int numberOfItems; // variable to store the number of
  // items in the dispenser
  int cost; // variable to store the cost of an item
};

#include <iostream>
using namespace std;
int cashRegister::getCurrentBalance() const { return cashOnHand; }
void cashRegister::acceptAmount(int amountIn) {
  cashOnHand = cashOnHand + amountIn;
}
cashRegister::cashRegister(int cashIn) {
  if (cashIn >= 0)
    cashOnHand = cashIn;
  else
    cashOnHand = 500;
}

int dispenserType::getNoOfItems() const { return numberOfItems; }
int dispenserType::getCost() const { return cost; }
void dispenserType::makeSale() { numberOfItems--; }
dispenserType::dispenserType(int setNoOfItems, int setCost) {
  if (setNoOfItems >= 0)
    numberOfItems = setNoOfItems;
  else
    numberOfItems = 50;
  if (setCost >= 0)
    cost = setCost;
  else
    cost = 50;
}

using namespace std;
void showSelection();
void sellProduct(dispenserType &product, cashRegister &pCounter);
int main() {
  cashRegister counter;
  dispenserType orange(100, 50);
  dispenserType apple(100, 65);
  dispenserType mango(75, 80);
  dispenserType strawberrybanana(100, 85);
  int choice; // variable to hold the selection
  showSelection();
  cin >> choice;

  while (choice != 9) {
    switch (choice) {
    case 1:
      sellProduct(orange, counter);
      break;
    case 2:
      sellProduct(apple, counter);
      break;
    case 3:
      sellProduct(mango, counter);
      break;
    case 4:
      sellProduct(strawberrybanana, counter);
      break;
    default:
      cout << "Invalid selection." << endl;
    } // end switch
    showSelection();
    cin >> choice;
  } // end while
  return 0;
} // end main
void showSelection() {
  cout << "*** Welcome to Shelly's Juice Shop ***" << endl;
  cout << "To select an item, enter " << endl;
  cout << "1 for orange juice" << endl;
  cout << "2 for apple juice" << endl;
  cout << "3 for mango juice" << endl;
  cout << "4 for strawberry banana" << endl;
  cout << "9 to exit" << endl;
} // end showSelection
void sellProduct(dispenserType &product, cashRegister &pCounter) {
  int amount;                     // variable to hold the amount entered
  int amount2;                    // variable to hold the extra amount needed
  if (product.getNoOfItems() > 0) // if the dispenser is not
  // empty
  {
    cout << "Please deposit " << product.getCost() << " cents" << endl;
    cin >> amount;
    if (amount < product.getCost()) {
      cout << "Please deposit another " << product.getCost() - amount
           << " cents" << endl;
      cin >> amount2;
      amount = amount + amount2;
    }
  }
}